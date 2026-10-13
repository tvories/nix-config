#!/usr/bin/env fish
# Report garbage-collection health and disk usage on the NixOS hosts.
# Usage: fish scripts/gc-status.fish [host ...]   (default: nas3 homebox tback)
# Read-only: no sudo, nothing is deleted.

set -l hosts $argv
test (count $hosts) -eq 0; and set hosts nas3 homebox tback

# Runs remotely under bash (login shell is fish). No single quotes allowed
# inside this block, since it is a fish single-quoted string.
set -l remote '
hr() { printf "\n--- %s ---\n" "$1"; }

hr "timers"
systemctl list-timers --all --no-pager "nix-gc*" "nh-clean*" "docker-prune*" 2>/dev/null

hr "gc runs, last 30 days"
journalctl -u nix-gc -u nh-clean --since -30d --no-pager 2>/dev/null \
  | grep -Ei "freed|deleted|removing|fail|error" | tail -n 10

# Count generation links directly: nix-env --list-generations needs the
# profile lock, which non-root users cannot take on some hosts.
hr "system generations"
ls -1 /nix/var/nix/profiles/ | grep -E "^system-[0-9]+-link$" | sort -t- -k2 -n | tail -n 5
echo "total: $(ls -1 /nix/var/nix/profiles/ | grep -cE "^system-[0-9]+-link$")"

hr "home-manager generations (all users)"
for d in /home/*/.local/state/nix/profiles /nix/var/nix/profiles/per-user/*; do
  n=$(ls -1 "$d" 2>/dev/null | grep -cE "^home-manager-[0-9]+-link$")
  [ "$n" -gt 0 ] && echo "$d: $n"
done

hr "gc roots outside profiles"
nix-store --gc --print-roots 2>/dev/null \
  | grep -v -e "^\"/proc" -e "/nix/var/nix/profiles" -e "censored" \
            -e "home-manager-[0-9]*-link" -e "gcroots/current-home" | head -n 15

hr "collectable now"
echo "$(nix-store --gc --print-dead 2>/dev/null | grep -c .) dead store paths"

hr "disk"
df -h / /nix /boot 2>/dev/null | awk "!seen[\$0]++"
store=$(timeout 30 du -sh /nix/store 2>/dev/null | cut -f1)
echo "nix store: ${store:-(du took over 30s, skipped)}"
journalctl --disk-usage 2>/dev/null

hr "docker"
docker system df 2>/dev/null || echo "(docker not available to this user)"

if command -v zfs >/dev/null; then
  hr "zfs"
  zfs list -o name,used,usedsnap,avail -d 1 2>/dev/null
fi
'

for h in $hosts
    echo
    set_color --bold blue
    echo "===================== $h ====================="
    set_color normal
    printf '%s\n' $remote | ssh -o ConnectTimeout=5 taylor@$h.mcbadass.local bash -s
    or begin
        set_color red
        echo "(ssh to $h failed)"
        set_color normal
    end
end
