# Claude Slash Commands — tvories/nix-config

Custom slash commands for Claude CLI. Each `.md` file in this directory becomes a `/command-name` shortcut.

---

## Quick Reference

| Command | Arguments | Description |
|---|---|---|
| `/nixos-deploy` | `<hostname>` | Build, diff, confirm, and switch a NixOS host |
| `/darwin-deploy` | `<hostname>` | Build, diff, confirm, and switch a Darwin host |
| `/new-service` | `<name>` | Scaffold a new NixOS service module |
| `/check` | _(none)_ | Run `nix flake check` and triage errors |
| `/sops-edit` | `<hostname>` | Inspect and edit SOPS secrets for a host |

---

## Command Details

### 🚀 `/nixos-deploy <hostname>`

Runs a full build → diff → confirm → switch cycle for a NixOS host.

- Calls `task nix:build-nixos host=<hostname>` first
- Shows the `nvd` diff before asking to proceed
- Calls `task nix:apply-nixos host=<hostname>` on confirmation
- Stops on build failure — never applies a broken config

**Valid hosts:** `nas3`, `nas-vm`, `tback`, `homebox`, `wsl`

```
/nixos-deploy nas3
/nixos-deploy tback
```

---

### 🍎 `/darwin-deploy <hostname>`

Same build → diff → confirm → switch flow for nix-darwin hosts.

- Calls `task nix:build-darwin host=<hostname>` then `task nix:apply-darwin`
- Darwin deploys run locally (not via SSH)

**Valid hosts:** `DVA-YY669XDT42` (personal, aarch64), `DVA-C02CQ7GCMD6T` (work, x86_64)

```
/darwin-deploy DVA-YY669XDT42
```

---

### 🛠️ `/new-service <name>`

Scaffolds a new NixOS service module under `hosts/_modules/nixos/services/<name>/`.

- Creates `default.nix` with the standard `modules.services.<name>` option pattern
- Adds the import to `hosts/_modules/nixos/services/default.nix`
- Does **not** enable the module on any host — that's left to you

```
/new-service paperless
/new-service vaultwarden
```

---

### ✅ `/check`

Runs `nix flake check --keep-going` and triages any errors against known repo conventions.

- Groups errors by host/output
- Suggests likely fixes (missing imports, type errors, undefined vars)
- Does not auto-fix — presents findings and waits

```
/check
```

---

### 🔐 `/sops-edit <hostname>`

Guides editing SOPS secrets for a given host.

- Decrypts and displays current secrets (without printing raw values to stdout)
- Opens `sops hosts/<hostname>/secret.sops.yaml` for editing
- Verifies re-encryption after save
- Reminds you of the Nix reference pattern

```
/sops-edit nas3
/sops-edit tback
```

---

## Recommended Workflows

### Safe Deployment
```
/check                        # verify flake is clean
/nixos-deploy homebox         # build → diff → confirm → switch
```

### New Service Module
```
/new-service vaultwarden      # scaffold module files
# edit the module to implement the service
/check                        # verify no eval errors
/nixos-deploy homebox         # deploy to target host
```

### Add a Secret
```
/sops-edit nas3               # add secret to host secrets file
# reference sops.secrets.<name> in your nix config
/nixos-deploy nas3            # deploy with new secret
```

---

## Host Reference

| Hostname | System | IP | Role |
|---|---|---|---|
| `nas3` | x86_64-linux | 192.168.1.24 | Physical NAS, ZFS `ook`, Samba, NFS |
| `nas-vm` | x86_64-linux | 192.168.1.230 | VM clone of NAS (testing) |
| `tback` | aarch64-linux | DHCP | RPi 4, restic backup server |
| `homebox` | x86_64-linux | .43/.243/.240 | DNS (Technitium), primary services |
| `wsl` | x86_64-linux | — | NixOS-WSL dev environment |
| `DVA-YY669XDT42` | aarch64-darwin | — | Personal MacBook |
| `DVA-C02CQ7GCMD6T` | x86_64-darwin | — | Work MacBook |

---

## Notes

- Commands use `task` (go-task) from `.taskfiles/nix/Taskfile.yaml`
- SSH targets resolve as `taylor@<hostname>.mcbadass.local`
- SOPS age keys are per-host; defined in `.sops.yaml` at repo root
- Keep this README in sync when adding new commands
