# Claude Instructions — tvories/nix-config

## Repository Overview

Personal NixOS homelab + macOS configuration managed as a Nix flake.
Primary user: `taylor` (uid/gid 1000). Darwin username: `tvories`.
Default shell: `fish`. Theme: Catppuccin macchiato.
Internal domain: `mcbadass.local`. External domain: `t-vo.us`.
Nixpkgs stable: `nixos-25.11`. `system.stateVersion = "25.11"`.

---

## Host Inventory

| Hostname           | System           | Role / Notes                                              | IP(s)                          |
|--------------------|------------------|-----------------------------------------------------------|--------------------------------|
| `nas3`             | x86_64-linux     | Physical NAS, ZFS pool `ook`, Samba, NFS, Traefik, Docker | 192.168.1.24                   |
| `nas-vm`           | x86_64-linux     | VM clone of NAS for testing; mirrors nas3 setup           | 192.168.1.230                  |
| `tback`            | aarch64-linux    | Raspberry Pi 4; backup server (restic), Wireguard, Traefik | DHCP                           |
| `homebox`          | x86_64-linux     | Primary services host; Technitium DNS, Traefik, Docker     | .43 / .243 / .240              |
| `wsl`              | x86_64-linux     | NixOS-WSL dev environment                                 | —                              |
| `DVA-YY669XDT42`   | aarch64-darwin   | Personal MacBook                                          | —                              |
| `DVA-C02CQ7GCMD6T` | x86_64-darwin    | Work MacBook                                              | —                              |

---

## Repository Architecture

```
flake.nix                          # Entry point; defines all nixosConfigurations + darwinConfigurations
lib/mkSystem.nix                   # mkNixosSystem / mkDarwinSystem builders
hosts/
  _modules/
    common/                        # Shared NixOS + Darwin (locale, nix settings, shells)
    nixos/                         # NixOS-only modules (services/, filesystems/, users, sops, packages)
    darwin/                        # Darwin-only modules
  <hostname>/
    default.nix                    # Host-specific config; enables modules, sets networking, users
    hardware-configuration.nix     # Generated hardware config
    secret.sops.yaml               # Encrypted SOPS secrets for this host
homes/
  _modules/                        # Reusable home-manager modules
  taylor/
    default.nix                    # Base home config; imports _modules + host overlay
    hosts/<hostname>.nix           # Host-specific home-manager overrides
    secrets/                       # Home-manager SOPS secrets
pkgs/                              # Custom packages (nvim, shcopy, usage)
overlays/                          # Nixpkgs overlays
```

### Module Load Order (NixOS)
`hosts/_modules/common` → `hosts/_modules/nixos` → `hosts/<hostname>`

### Module Load Order (Darwin)
`hosts/_modules/common` → `hosts/_modules/darwin` → `hosts/<hostname>`

### Home-Manager
Loaded via `home-manager.users.taylor = ../homes/taylor` (NixOS) or `users.tvories` (Darwin).
Host-specific overrides live in `homes/taylor/hosts/<hostname>.nix`.

---

## NixOS Module Namespace

All custom modules use the `modules.*` option namespace, not raw NixOS options.

### Services (`modules.services.<name>`)
Available: `traefik`, `docker`, `samba`, `nfs`, `node-exporter`, `smartd`, `smartctl-exporter`,
`msmtp`, `openssh`, `chrony`, `k3s`, `restic-server`, `zfs-exporter`, `technitium`,
`cfdyndns`, `bind`, `blocky`, `dnsdist`, `minio`, `nginx`, `onepassword-connect`, `podman`

Enable pattern:
```nix
modules.services.traefik = {
  enable = true;
  domain = "t-vo.us";
  sans = [ "*.t-vo.us" "host.t-vo.us" ];
  dashboardHost = "host.t-vo.us";
  # routers and services defined in per-service .nix files, not here
};
```

### Filesystems (`modules.filesystems.zfs`)
```nix
modules.filesystems.zfs = {
  enable = true;
  mountPoolsAtBoot = [ "ook" ];
};
```

### Users (`modules.users`)
```nix
modules.users = {
  additionalUsers = { <username> = { isNormalUser = true; ... }; };
  groups = { <groupname> = { gid = 12345; members = [ "taylor" ]; }; };
};
```

Use `ifGroupsExist` for optional group membership:
```nix
let ifGroupsExist = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
```

---

## Home-Manager Module Namespace

Modules live under `modules.*` in home configs:
- `modules.editor.nvim` / `modules.editor.vscode`
- `modules.shell.fish` / `modules.shell.gcloud` / `modules.shell.go-task`
- `modules.themes.catppuccin`
- `modules.deployment.*` / `modules.development.*` / `modules.security.*`
- `modules.kubernetes.*` / `modules.virtualisation.*`

---

## Adding a New NixOS Service Module

1. Create `hosts/_modules/nixos/services/<name>/default.nix` following this pattern:
```nix
{ lib, config, pkgs, ... }:
let cfg = config.modules.services.<name>; in
{
  options.modules.services.<name> = {
    enable = lib.mkEnableOption "<name>";
    # additional options...
  };
  config = lib.mkIf cfg.enable {
    # actual NixOS config
  };
}
```
2. Add `./\<name>` to `hosts/_modules/nixos/services/default.nix` imports.
3. Enable on a host: `modules.services.<name>.enable = true;`
4. If secrets are needed, add `sops.secrets.<name> = { sopsFile = ./secret.sops.yaml; };`

---

## Adding a New Host

1. Create `hosts/<hostname>/default.nix` + `hardware-configuration.nix`
2. Add to `flake.nix` under `nixosConfigurations` (or `darwinConfigurations`):
   ```nix
   <hostname> = mkSystemLib.mkNixosSystem "<arch>-linux" "<hostname>" flake-packages;
   ```
3. Generate an age key for the host and add it to `.sops.yaml`
4. Create `homes/taylor/hosts/<hostname>.nix` (can be empty `{}` initially)

---

## Deployment Commands

### NixOS (remote via SSH)
```bash
task nix:build-nixos host=<hostname>    # dry-run build + diff
task nix:apply-nixos host=<hostname>    # build + switch (prompts to confirm)
```
Targets `taylor@<hostname>.mcbadass.local` via SSH.

### Darwin
```bash
task nix:build-darwin host=<hostname>   # build + diff
task nix:apply-darwin host=<hostname>   # build + switch (prompts to confirm)
```

### Direct (on the target machine)
```bash
nixos-rebuild switch --flake .#<hostname>
darwin-rebuild switch --flake .#<hostname>
```

---

## Secret Management (SOPS)

- Secrets encrypted with age (per-host keys) + GCP KMS (`projects/taylor-cloud/...`)
- Host age keys defined in `.sops.yaml`; creation rules apply to `*.sops.yaml` files
- Per-host secrets: `hosts/<hostname>/secret.sops.yaml`
- Per-home secrets: `homes/taylor/secrets/`
- Reference in Nix: `sops.secrets.<name> = { sopsFile = ./secret.sops.yaml; };`
- Task helpers: `task sops:*`

**NEVER:**
- Commit unencrypted secrets
- Hardcode secrets, passwords, or API keys in `.nix` files
- Put secrets in the Nix store directly (use `sops.secrets` paths)

---

## Conventions (NEVER VIOLATE)

- All custom NixOS options live under the `modules.*` namespace
- Prefer native NixOS service modules over Docker when a good module exists
- Docker is acceptable for services without quality NixOS modules (managed via `modules.services.docker`)
- Traefik handles all ingress; services declare their own routers/services in their `.nix` files, not in the host's traefik block
- `hostname` is always passed via `specialArgs` — use it instead of hardcoding hostnames
- SSH public keys sourced from `homes/taylor/config/ssh/ssh.pub` (not hardcoded inline)
- Do not modify `hardware-configuration.nix` — it is machine-generated
- `system.stateVersion` must not be changed after initial setup

---

## Anti-Patterns

- ❌ `services.traefik.dynamicConfigOptions` directly in host config — use the module
- ❌ Inline `users.users` config outside the module system — use `modules.users.additionalUsers`
- ❌ Hardcoded IPs in service URLs when a localhost reference works
- ❌ Adding packages to `environment.systemPackages` when a module option exists
- ❌ Using `nixpkgs-unstable` for packages available and working in stable without justification

---

## Nix Style

- 2-space indentation
- Trailing commas in lists/attrs
- `lib.mkIf`, `lib.mkOption`, `lib.mkEnableOption` for option definitions
- `lib.mkMerge` / `lib.optionalAttrs` for conditional config composition
- Comments on uncommented-out sections should explain *why*, not *what*

---

## Maintaining These Instructions

Update this file when:
- A new host is added or an existing host changes role
- A new service module is added to `hosts/_modules/nixos/services/`
- Deployment commands or tooling changes
- New conventions are established
