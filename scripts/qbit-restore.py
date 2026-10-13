#!/usr/bin/env python3
"""Find qBittorrent torrents with missing files, locate them in a ZFS snapshot,
and restore them interactively. Run on nas3 as root.

  QBIT_URL=http://qbittorrent:8080 QBIT_USER=admin PATH_MAP=/data=/ook/Media \
    sudo -E nix-shell -p python3 --run "python3 scripts/qbit-restore.py"         # report
  ... --run "python3 scripts/qbit-restore.py --interactive"                      # decide + apply

Env:
  QBIT_URL, QBIT_USER, QBIT_PASS (prompted if unset)
  PATH_MAP   container=host prefixes, comma separated (e.g. /data=/ook/Media)
  SNAPSHOT   default zrepl_daily_20240125_100001_000
  SEARCH     live dirs whose snapshot copies are indexed
             (default /ook/Media/books,/ook/Media/downloads,/ook/Media/ebooks)
  UPLOADS    Calibre import folder (default /ook/Media/ebooks/Calibre Library/uploads)
  ABS_ROOT   Audiobookshelf library root for the L choice (default /ook/Media/books)
  DL_AUDIO   where R puts torrents the library already has (default /ook/Media/downloads/audiobooks)

Nothing is written until you confirm the plan. Existing files are never overwritten.
Restoring one file to several places hardlinks the extra copies (as Chaptarr would),
except Audiobookshelf (L), which always gets an independent copy.
"""

import argparse
import filecmp
import getpass
import http.cookiejar
import json
import os
import stat
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from collections import defaultdict

SNAPSHOT = os.environ.get("SNAPSHOT", "zrepl_daily_20240125_100001_000")
SEARCH = os.environ.get("SEARCH", "/ook/Media/books,/ook/Media/downloads,/ook/Media/ebooks").split(",")
UPLOADS = os.environ.get("UPLOADS", "/ook/Media/ebooks/Calibre Library/uploads")
ABS_ROOT = os.environ.get("ABS_ROOT", "/ook/Media/books")
DL_AUDIO = os.environ.get("DL_AUDIO", "/ook/Media/downloads/audiobooks")
# Library matches are by exact size; below this, covers/nfo/cue sizes collide.
LIB_MIN_SIZE = 1024 * 1024
MAPPING = []
AUDIO_EXT = {".mp3", ".m4b", ".m4a", ".flac", ".ogg", ".opus", ".aac", ".wma", ".wav"}
AUDIO_CATEGORY = os.environ.get("QBIT_AUDIO_CATEGORY", "audiobooks")
EBOOK_EXT = {".epub", ".mobi", ".azw", ".azw3", ".pdf", ".cbz", ".cbr", ".fb2", ".djvu"}
SNAP_SEG = f"/.zfs/snapshot/{SNAPSHOT}"


class Qbit:
    def __init__(self, url, user, password):
        self.url = url.rstrip("/")
        self.jar = http.cookiejar.CookieJar()
        self.opener = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(self.jar))
        try:
            body = self._post("/api/v2/auth/login", username=user, password=password).strip()
        except urllib.error.HTTPError as e:
            sys.exit(f"qBittorrent login failed: HTTP {e.code} {e.reason}\n{e.read()[:300].decode(errors='replace')}")
        # Newer versions may reply with an empty body and name the cookie
        # QBT_SID_<port>; an authenticated call is the real test.
        if body != "Ok.":
            try:
                self._get_text("/api/v2/app/version")
            except urllib.error.HTTPError as e:
                cookies = [c.name for c in self.jar]
                sys.exit(f"qBittorrent login failed for user {user!r} at {self.url}\n"
                         f"login response: {body[:300]!r}, cookies: {cookies}, "
                         f"auth check: HTTP {e.code}")

    def _open(self, req, tries=4):
        # One new HTTPS connection per call through the reverse proxy; an
        # occasional connect timeout shouldn't abort a long run.
        for attempt in range(tries):
            try:
                return self.opener.open(req, timeout=30).read().decode()
            except urllib.error.HTTPError:
                raise
            except (urllib.error.URLError, TimeoutError, ConnectionError) as e:
                if attempt == tries - 1:
                    raise
                wait = 2 ** (attempt + 1)
                print(f"  ({e}; retrying in {wait}s)", file=sys.stderr)
                time.sleep(wait)

    def _post(self, path, **data):
        req = urllib.request.Request(self.url + path, data=urllib.parse.urlencode(data).encode(),
                                     headers={"Referer": self.url})
        return self._open(req)

    def _get_text(self, path, **params):
        q = "?" + urllib.parse.urlencode(params) if params else ""
        req = urllib.request.Request(self.url + path + q, headers={"Referer": self.url})
        return self._open(req)

    def _get(self, path, **params):
        return json.loads(self._get_text(path, **params))

    def all(self):
        return self._get("/api/v2/torrents/info")

    def missing(self):
        return [t for t in self.all() if t["state"] == "missingFiles"]

    def categories(self):
        return self._get("/api/v2/torrents/categories")

    def set_location(self, hashes, location):
        self._post("/api/v2/torrents/setLocation", hashes="|".join(hashes), location=location)

    def set_category(self, hashes, category):
        self._post("/api/v2/torrents/setCategory", hashes="|".join(hashes), category=category)

    def set_auto_management(self, hashes, enable=True):
        self._post("/api/v2/torrents/setAutoManagement", hashes="|".join(hashes),
                   enable="true" if enable else "false")

    def files(self, h):
        return self._get("/api/v2/torrents/files", hash=h)

    def recheck(self, hashes):
        self._post("/api/v2/torrents/recheck", hashes="|".join(hashes))


# ---------- paths ----------

def path_map():
    pairs = []
    for item in filter(None, os.environ.get("PATH_MAP", "").split(",")):
        src, _, dst = item.partition("=")
        pairs.append((src.rstrip("/"), dst.rstrip("/")))
    return sorted(pairs, key=lambda p: len(p[0]), reverse=True)


def to_host(path, mapping):
    for src, dst in mapping:
        if path == src or path.startswith(src + "/"):
            return dst + path[len(src):]
    return path


def to_container(path):
    """Host path -> the path qBittorrent sees, for its Set Location dialog."""
    for src, dst in sorted(MAPPING, key=lambda p: len(p[1]), reverse=True):
        if path == dst or path.startswith(dst + "/"):
            return src + path[len(dst):]
    return path


MOUNTS = []


def load_mounts():
    out = subprocess.run(["zfs", "list", "-H", "-o", "mountpoint", "-t", "filesystem"],
                         capture_output=True, text=True, check=True).stdout.split()
    MOUNTS.extend(sorted((m for m in out if m.startswith("/")), key=len, reverse=True))


def snap_of(live):
    for m in MOUNTS:
        if live == m or live.startswith(m.rstrip("/") + "/"):
            return os.path.join(m, SNAP_SEG.lstrip("/"), os.path.relpath(live, m))
    return None


def live_of(snap):
    return snap.replace(SNAP_SEG, "", 1)


# ---------- snapshot index ----------

def build_index():
    """Index regular files under SEARCH in the snapshot by inode and by (name, size)."""
    by_ino, by_key, by_snap = defaultdict(list), defaultdict(list), {}
    count = 0
    for root in SEARCH:
        sroot = snap_of(root.rstrip("/"))
        if not sroot or not os.path.isdir(sroot):
            print(f"  (not in snapshot: {root})", file=sys.stderr)
            continue
        for dirpath, _, files in os.walk(sroot):
            for fn in files:
                p = os.path.join(dirpath, fn)
                try:
                    st = os.lstat(p)
                except OSError:
                    continue
                if not stat.S_ISREG(st.st_mode):
                    continue
                rec = {"snap": p, "live": live_of(p), "size": st.st_size,
                       "ino": (st.st_dev, st.st_ino)}
                by_snap[p] = rec
                by_key[(fn, st.st_size)].append(rec)
                if st.st_nlink > 1:
                    by_ino[rec["ino"]].append(rec)
                count += 1
                if count % 20000 == 0:
                    print(f"  indexed {count} files...", file=sys.stderr)
    print(f"  indexed {count} snapshot files", file=sys.stderr)
    return by_ino, by_key, by_snap


def build_library_index():
    """Current (live) Audiobookshelf library files by size."""
    by_size = defaultdict(list)
    for dirpath, _, files in os.walk(ABS_ROOT):
        for fn in files:
            p = os.path.join(dirpath, fn)
            try:
                size = os.path.getsize(p)
            except OSError:
                continue
            if size >= LIB_MIN_SIZE:
                by_size[size].append(p)
    return by_size


def locate(dst, size, idx):
    """Return (source snapshot path or None, [snapshot records of other places it lived])."""
    by_ino, by_key, by_snap = idx
    expected = snap_of(dst)
    recs = []
    if expected in by_snap and by_snap[expected]["size"] == size:
        recs.append(by_snap[expected])
    recs += by_key.get((os.path.basename(dst), size), [])
    # Hardlinks share an inode even when readarr renamed the library copy.
    for r in list(recs):
        recs += by_ino.get(r["ino"], [])
    seen, uniq = set(), []
    for r in recs:
        if r["snap"] not in seen:
            seen.add(r["snap"])
            uniq.append(r)
    src = uniq[0]["snap"] if uniq else None
    elsewhere = [r for r in uniq if r["live"] != dst]
    # A surviving live copy can be hardlinked instead of copying from the snapshot.
    twin = next((r["live"] for r in elsewhere
                 if os.path.isfile(r["live"]) and os.path.getsize(r["live"]) == size), None)
    return src, elsewhere, twin


# ---------- planning ----------

def survey(qb, mapping, idx, library):
    items, unmapped = [], set()
    for t in qb.missing():
        save = to_host(t["save_path"], mapping)
        if not snap_of(save):
            unmapped.add(t["save_path"])
        files = []
        for f in qb.files(t["hash"]):
            dst = os.path.join(save, f["name"])
            if os.path.exists(dst):
                continue
            src, elsewhere, twin = locate(dst, f["size"], idx)
            in_lib = [p for p in library.get(f["size"], []) if p != dst]
            files.append({"name": f["name"], "size": f["size"], "dst": dst,
                          "src": src, "elsewhere": elsewhere, "twin": twin, "in_lib": in_lib})
        items.append({"torrent": t, "save": save, "files": files})
    if unmapped:
        print("\nWARNING: these qBittorrent paths don't map onto a ZFS dataset; check PATH_MAP.\n"
              "Restores there will be skipped:\n  " + "\n  ".join(sorted(unmapped)))
    return items


def show(item):
    t, files = item["torrent"], item["files"]
    found = [f for f in files if f["src"]]
    print(f"\n=== {t['name']}")
    print(f"    qBittorrent path: {item['save']}")
    twins = sum(1 for f in files if f["twin"])
    print(f"    missing files: {len(files)}, found in snapshot: {len(found)}, "
          f"not found: {len(files) - len(found)}, still on disk elsewhere (hardlinkable): {twins}")
    for f in files[:8]:
        mark = "found" if f["src"] else "NOT FOUND"
        print(f"      [{mark}] {f['name']}")
        for r in f["elsewhere"][:3]:
            now = " (still exists)" if os.path.exists(r["live"]) else ""
            print(f"          also was at: {r['live']}{now}")
    if len(files) > 8:
        print(f"      ... {len(files) - 8} more")
    big = [f for f in files if f["size"] >= LIB_MIN_SIZE]
    have = [f for f in big if f["in_lib"]]
    if big:
        print(f"    Audiobookshelf check: {len(have)} of {len(big)} audio/large files already "
              f"in {ABS_ROOT} (matched by size)")
        for d in sorted({os.path.dirname(p) for f in have for p in f["in_lib"]})[:4]:
            print(f"      library has: {d}")
        if have and len(have) == len(big):
            print(f"    -> looks already fixed in the library; R restores it under {DL_AUDIO} instead")


def options_for(item):
    """Lettered destination choices. Each maps to a function file -> destination path."""
    opts = {"A": (f"qBittorrent path {item['save']} (restores seeding)", lambda f: f["dst"])}
    # Group former locations by directory so each becomes its own choice.
    dirs = []
    for f in item["files"]:
        for r in f["elsewhere"]:
            d = os.path.dirname(r["live"])
            if d not in dirs and not d.startswith(item["save"]):
                dirs.append(d)
    for letter, d in zip("BCDEFGHIJK", dirs):
        def pick(f, d=d):
            for r in f["elsewhere"]:
                if os.path.dirname(r["live"]) == d:
                    return r["live"]
            return None
        opts[letter] = (f"where it was before: {d}", pick)
    opts["R"] = (f"{DL_AUDIO} (library already has it; then set qBittorrent location to "
                 f"{to_container(DL_AUDIO)})",
                 lambda f: os.path.join(DL_AUDIO, f["name"]))
    if any(os.path.splitext(f["name"])[1].lower() in EBOOK_EXT for f in item["files"]):
        opts["U"] = (f"Calibre uploads (Calibre imports, then removes it): {UPLOADS}",
                     lambda f: os.path.join(UPLOADS, os.path.basename(f["name"]))
                     if os.path.splitext(f["name"])[1].lower() in EBOOK_EXT else None)
    return opts


def is_library_path(path):
    return path == ABS_ROOT or path.startswith(ABS_ROOT.rstrip("/") + "/")


def import_candidate(item, ans):
    """Where this torrent lands outside the library, plus its library-match counts."""
    if "R" in ans:
        base = DL_AUDIO
    elif "A" in ans and not is_library_path(item["save"]):
        base = item["save"]
    else:
        return None
    top = item["files"][0]["name"].split("/")[0]
    big = [f for f in item["files"] if f["size"] >= LIB_MIN_SIZE]
    return {"torrent": item["torrent"]["name"], "path": to_container(os.path.join(base, top)),
            "have": sum(1 for f in big if f["in_lib"]), "big": len(big)}


def read_dir(prompt, base=None):
    d = input(prompt).strip().strip('"').strip("'")
    if d and base and not d.startswith("/"):
        d = os.path.join(base, d)
    return d


def ask(item):
    """Return (answer letters, [(description, file -> dst, independent copy?)])."""
    opts = options_for(item)
    for k, (desc, _) in opts.items():
        print(f"    {k}) {desc}")
    print(f"    L) Audiobookshelf, independent copy (asks for a folder under {ABS_ROOT})")
    print("    P) paste a destination directory   S) skip   Q) quit and review plan")
    # Never restore straight into the library (Chaptarr imports from downloads);
    # torrents already under downloads go back in place.
    default = "R" if is_library_path(item["save"]) else "A"
    while True:
        ans = input(f"    choice (several allowed, e.g. AL) [Enter = {default}]: ").strip().upper() or default
        if ans in ("S", "Q"):
            return ans, []
        if not ans or not all(c in opts or c in "LP" for c in ans):
            print("    not a valid choice")
            continue
        chosen = [(*opts[c], False) for c in ans if c in opts]
        if "L" in ans:
            d = read_dir(f"    Audiobookshelf folder, e.g. author name (relative to {ABS_ROOT}): ", ABS_ROOT)
            if not d:
                continue
            # The torrent's own top folder (usually the title) is kept under it.
            chosen.append((f"Audiobookshelf {d}", lambda f, d=d: os.path.join(d, f["name"]), True))
        if "P" in ans:
            d = read_dir("    destination directory: ")
            if not d:
                continue
            chosen.append((f"pasted {d}", lambda f, d=d: os.path.join(d, f["name"]), False))
        return ans, chosen


def plan_for(item, chosen):
    steps = []
    for f in item["files"]:
        if not f["src"]:
            continue
        # Prefer hardlinking a surviving file (old location, else a library match).
        link = f["twin"] or (f["in_lib"][0] if f["in_lib"] else None)
        for desc, fn, independent in chosen:
            dst = fn(f)
            if dst:
                steps.append({"torrent": item["torrent"]["name"], "src": f["src"], "dst": dst,
                              "copy": independent, "link": None if independent else link,
                              "in_lib": [p for p in f["in_lib"] if p != dst]})
    return steps


def review(steps, repoint):
    lib = [s for s in steps if s["dst"].startswith(ABS_ROOT.rstrip("/") + "/")]
    other = [s for s in steps if s not in lib]
    print(f"\n===== Going into {ABS_ROOT}: {len(lib)} files (full list) =====")
    current = None
    for s in lib:
        if s["torrent"] != current:
            current = s["torrent"]
            print(f"\n  [{current}]")
        how = "copy" if s["copy"] else ("link" if s["link"] else "snap")
        print(f"    {how}  {s['dst']}")
        for p in s["in_lib"][:2]:
            print(f"          !! library already has a same-size file: {p}")
    dupes = sum(1 for s in lib if s["in_lib"])
    if dupes:
        print(f"\n  !! {dupes} of these look like duplicates of files already in the library")
    print(f"\n===== Elsewhere: {len(other)} files =====")
    for s in other[:20]:
        how = "copy" if s["copy"] else ("link" if s["link"] else "snap")
        print(f"    {how}  {s['dst']}")
    if len(other) > 20:
        print(f"    ... {len(other) - 20} more")
    print("\n  link = hardlink to a file still on disk, snap = copied from the snapshot, "
          "copy = independent copy")
    if repoint:
        print("\n===== After applying, set these locations in qBittorrent "
              "(right-click > Set location), then Force Recheck =====")
        for name, loc in repoint:
            print(f"    {name}\n        -> {loc}")


# ---------- applying ----------

def make_parents(dst, src):
    missing, d, s = [], os.path.dirname(dst), os.path.dirname(src)
    while not os.path.isdir(d):
        missing.append((d, s))
        d, s = os.path.dirname(d), os.path.dirname(s)
    for d, s in reversed(missing):
        os.mkdir(d)
        if os.path.isdir(s):
            st = os.stat(s)
            os.chown(d, st.st_uid, st.st_gid)
            os.chmod(d, st.st_mode & 0o7777)


def apply(steps):
    restored = {}  # snapshot source -> first live copy, to hardlink duplicates
    done, skipped = 0, []
    for s in steps:
        src, dst = s["src"], s["dst"]
        if os.path.exists(dst):
            print(f"  exists, skipped: {dst}")
            skipped.append(dst)
            continue
        if not snap_of(dst):
            print(f"  outside ZFS datasets, skipped: {dst}")
            skipped.append(dst)
            continue
        make_parents(dst, src)
        prev = None if s["copy"] else (restored.get(src) or s.get("link"))
        if prev and os.stat(prev).st_dev == os.stat(os.path.dirname(dst)).st_dev:
            os.link(prev, dst)
            print(f"  hardlinked: {dst}")
        else:
            subprocess.run(["cp", "-a", "--no-clobber", src, dst], check=True)
            # Independent copies must never become a hardlink source.
            if not s["copy"]:
                restored.setdefault(src, dst)
            print(f"  copied:     {dst}")
        done += 1
    return done, skipped


def write_summary(steps, repoint, recheck_done, skipped, imports, path="qbit-restore-summary.txt"):
    per_torrent = defaultdict(int)
    for s in steps:
        per_torrent[s["torrent"]] += 1
    lines = ["qBittorrent restore summary", ""]
    if repoint:
        lines += ["TODO in qBittorrent: select these, Set location, then Force Recheck:"]
        for name, loc in repoint:
            lines.append(f"  {loc}  <-  {name}")
        lines.append("")
    todo = [c for c in imports if c["big"] == 0 or c["have"] < c["big"]]
    have = [c for c in imports if c not in todo]
    if todo:
        lines += ["TODO in Chaptarr Manual Import (no exact-size match in the library; it may still",
                  "exist re-encoded or renamed, so Manual Import will show if it's already there):"]
        for c in todo:
            lines.append(f"  {c['path']}    ({c['have']} of {c['big']} matched)")
        lines.append("")
    if have:
        lines += ["Already in the library (no import needed):"]
        lines += [f"  {c['torrent']}" for c in have]
        lines.append("")
    lines.append("Rechecked automatically: " + ("yes" if recheck_done else "no (Force Recheck the A torrents yourself)"))
    lines += ["", "Files restored per torrent:"]
    lines += [f"  {n:5d}  {name}" for name, n in sorted(per_torrent.items())]
    if skipped:
        lines += ["", "Skipped because the destination already existed (check these torrents):"]
        lines += [f"  {d}" for d in skipped]
    with open(path, "w") as fh:
        fh.write("\n".join(lines) + "\n")
    print("\n" + "\n".join(lines))
    print(f"\nSaved to {os.path.abspath(path)}")


def verify(fix, only=None, plan="qbit-restore-plan.json"):
    """Compare each restored file with its snapshot original; optionally replace mismatches."""
    with open(plan) as fh:
        steps = [s for s in json.load(fh) if not only or only.lower() in s["torrent"].lower()]
    recent = time.time() - 86400
    ok, bad = defaultdict(int), defaultdict(list)
    for i, s in enumerate(steps, 1):
        if i % 100 == 0:
            print(f"  compared {i}/{len(steps)}", file=sys.stderr)
        src, dst = s["src"], s["dst"]
        if not os.path.exists(dst):
            bad[s["torrent"]].append((s, "missing"))
            continue
        st = os.stat(dst)
        if st.st_size == os.path.getsize(src) and filecmp.cmp(src, dst, shallow=False):
            ok[s["torrent"]] += 1
            continue
        why = "differs from snapshot"
        if st.st_nlink > 1:
            why += f"; hardlinked ({st.st_nlink} links)"
        if st.st_mtime > recent:
            why += "; written in the last 24h"
        bad[s["torrent"]].append((s, why))

    for name in sorted(set(ok) | set(bad)):
        status = "OK" if not bad[name] else f"{len(bad[name])} BAD"
        print(f"{status:>8}  {name}  ({ok[name]} ok)")
        for s, why in bad[name][:5]:
            print(f"            {os.path.basename(s['dst'])}: {why}")
        if len(bad[name]) > 5:
            print(f"            ... {len(bad[name]) - 5} more")
    nbad = sum(len(v) for v in bad.values())
    print(f"\n{sum(ok.values())} files match the snapshot, {nbad} need fixing.")
    if not nbad:
        return
    if any("hardlinked" in why and "24h" in why for v in bad.values() for _, why in v):
        print("NOTE: some mismatched files are hardlinks written in the last 24h; qBittorrent may have\n"
              "      written into the shared library copy too. Check those books play correctly.")
    if not fix:
        print("Re-run with --verify --fix to replace them with copies from the snapshot.")
        return
    if input(f"Replace {nbad} files with fresh snapshot copies? [y/N] ").strip().lower() != "y":
        print("Nothing changed.")
        return
    for v in bad.values():
        for s, _ in v:
            if os.path.lexists(s["dst"]):
                os.unlink(s["dst"])  # drops only this name; a shared library copy is untouched
            make_parents(s["dst"], s["src"])
            subprocess.run(["cp", "-a", s["src"], s["dst"]], check=True)
            print(f"  replaced: {s['dst']}")
    print("Done. Force Recheck these torrents in qBittorrent (with them stopped).")


def repoint_torrents(qb):
    """Point torrents at DL_AUDIO when their data lives there and not at their current path."""
    target = to_container(DL_AUDIO)
    cands = []
    # Only torrents qBittorrent can't find data for can need repointing.
    torrents = [t for t in qb.all() if t["state"] in ("missingFiles", "error")]
    print(f"Checking {len(torrents)} torrents with missing files (read-only)...", file=sys.stderr)
    for i, t in enumerate(torrents, 1):
        if i % 50 == 0:
            print(f"  {i}/{len(torrents)}", file=sys.stderr)
        if t["save_path"].rstrip("/") == target.rstrip("/"):
            continue
        files = qb.files(t["hash"])
        current = to_host(t["save_path"], MAPPING)
        if not files or any(os.path.exists(os.path.join(current, f["name"])) for f in files):
            continue  # nothing to do, or data is still where qBittorrent expects it
        here = sum(os.path.exists(os.path.join(DL_AUDIO, f["name"])) for f in files)
        if here == 0:
            continue
        audio = any(os.path.splitext(f["name"])[1].lower() in AUDIO_EXT for f in files)
        cands.append({"t": t, "here": here, "total": len(files), "audio": audio})

    if not cands:
        print(f"No torrents need repointing to {target}.")
        return
    cat = qb.categories().get(AUDIO_CATEGORY)
    cat_path = (cat or {}).get("savePath", "").rstrip("/")
    if not cat:
        print(f"Category {AUDIO_CATEGORY!r} not found; will set location only.")
    elif cat_path != target.rstrip("/"):
        print(f"Category {AUDIO_CATEGORY!r} saves to {cat_path}, not {target}; "
              "will set location without enabling automatic management.")

    print(f"\nRepoint to {target}:")
    for c in cands:
        kind = f"category {AUDIO_CATEGORY}" if c["audio"] and cat else "location only (no audio files)"
        partial = "" if c["here"] == c["total"] else f"  [{c['here']}/{c['total']} files present]"
        print(f"  {c['t']['name']}  ({kind}){partial}")
    if input(f"\nRepoint, categorize and recheck these {len(cands)} torrents? [y/N] ").strip().lower() != "y":
        print("Nothing changed.")
        return

    hashes = [c["t"]["hash"] for c in cands]
    audio = [c["t"]["hash"] for c in cands if c["audio"]]
    # Explicit location first: with nothing at the old path, qBittorrent only updates
    # the path. ATM after that is a no-op move because the paths already match.
    qb.set_location(hashes, target)
    # setLocation is asynchronous; a recheck issued before it finishes checks the
    # old (empty) path, scores 0% and the torrent starts redownloading.
    pending = set(hashes)
    for _ in range(60):
        by_hash = {t["hash"]: t for t in qb.all()}
        pending = {h for h in pending
                   if by_hash.get(h, {}).get("save_path", "").rstrip("/") != target.rstrip("/")
                   or by_hash.get(h, {}).get("state") == "moving"}
        if not pending:
            break
        print(f"  waiting for {len(pending)} torrents to finish moving...", file=sys.stderr)
        time.sleep(5)
    if pending:
        names = [t["name"] for t in qb.all() if t["hash"] in pending]
        print("These did not switch location; NOT rechecking them:\n  " + "\n  ".join(names))
    if cat and audio:
        qb.set_category(audio, AUDIO_CATEGORY)
        if cat_path == target.rstrip("/"):
            qb.set_auto_management(audio, True)
    ready = [h for h in hashes if h not in pending]
    qb.recheck(ready)
    hashes = ready
    print(f"Repointed {len(hashes)} torrents"
          + (f", {len(audio)} set to category {AUDIO_CATEGORY}" if cat and audio else "")
          + "; recheck requested.")
    others = [c["t"]["name"] for c in cands if not c["audio"]]
    if others:
        print("Not audio (location set, no category); move these where they belong:")
        for n in others:
            print(f"  {n}")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--interactive", action="store_true", help="choose destinations, then apply")
    ap.add_argument("--repoint", action="store_true",
                    help=f"point torrents whose data is now under DL_AUDIO there, set category, recheck")
    ap.add_argument("--verify", action="store_true",
                    help="compare restored files (from qbit-restore-plan.json) with the snapshot")
    ap.add_argument("--fix", action="store_true", help="with --verify: replace mismatched files")
    ap.add_argument("--only", help="with --verify: only torrents whose name contains this text")
    args = ap.parse_args()

    if args.verify:  # local only; no qBittorrent login needed
        verify(args.fix, args.only)
        return

    url, user = os.environ.get("QBIT_URL"), os.environ.get("QBIT_USER")
    if not url or not user:
        sys.exit("set QBIT_URL and QBIT_USER")
    qb = Qbit(url, user, os.environ.get("QBIT_PASS") or getpass.getpass("qBittorrent password: "))
    load_mounts()
    MAPPING.extend(path_map())
    if args.repoint:
        repoint_torrents(qb)
        return
    print(f"Indexing snapshot {SNAPSHOT} under {', '.join(SEARCH)} ...", file=sys.stderr)
    idx = build_index()
    print(f"Indexing current library {ABS_ROOT} ...", file=sys.stderr)
    items = survey(qb, MAPPING, idx, build_library_index())
    # Flagged missingFiles but everything is on disk: only needs a recheck.
    already_ok = [i["torrent"]["hash"] for i in items if not i["files"]]
    items = [i for i in items if i["files"]]
    if already_ok:
        print(f"{len(already_ok)} torrents have all files on disk and only need a recheck")

    total = sum(len(i["files"]) for i in items)
    found = sum(1 for i in items for f in i["files"] if f["src"])
    print(f"\n{len(items)} torrents with missing files: {total} files, {found} found in snapshot")

    if not args.interactive:
        for item in items:
            show(item)
        print("\nReport only. Re-run with --interactive to choose destinations.")
        return

    steps, recheck, repoint, imports = [], list(already_ok), [], []
    for n, item in enumerate(items, 1):
        print(f"\n[{n}/{len(items)}]", end="")
        show(item)
        if not any(f["src"] for f in item["files"]):
            print("    nothing restorable, skipping")
            continue
        ans, chosen = ask(item)
        if ans == "Q":
            break
        if ans == "S":
            continue
        steps += plan_for(item, chosen)
        cand = import_candidate(item, ans)
        if cand:
            imports.append(cand)
        if "R" in ans:
            # Recheck only after you've repointed it in qBittorrent.
            repoint.append((item["torrent"]["name"], to_container(DL_AUDIO)))
        elif "A" in ans:
            recheck.append(item["torrent"]["hash"])

    if not steps:
        print("\nNothing planned.")
        if recheck and input(f"Recheck {len(recheck)} torrents in qBittorrent? [y/N] ").strip().lower() == "y":
            qb.recheck(recheck)
        return
    with open("qbit-restore-plan.json", "w") as fh:
        json.dump(steps, fh, indent=2)
    review(steps, repoint)
    print(f"\nPlan: {len(steps)} files (saved to qbit-restore-plan.json)")
    if input("Apply this plan? [y/N] ").strip().lower() != "y":
        print("Not applied.")
        return
    done, skipped = apply(steps)
    print(f"Restored {done} files.")
    recheck_done = False
    if recheck and input(f"Recheck {len(recheck)} torrents in qBittorrent? [y/N] ").strip().lower() == "y":
        qb.recheck(recheck)
        recheck_done = True
        print("Recheck requested.")
    write_summary(steps, repoint, recheck_done, skipped, imports)


if __name__ == "__main__":
    main()
