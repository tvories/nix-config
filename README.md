# nix-config

My personal NixOS homelab and macOS configuration managed as a Nix flake.

## Acknowledgements

This configuration draws inspiration and borrows patterns from several excellent public nix configs:

- **[carpenike/nix-config](https://github.com/carpenike/nix-config)** — CI workflow patterns, Renovate configuration, Copilot/Claude AI automation setup
- **[truxnell/nix-config](https://github.com/truxnell/nix-config)** — Renovate presets and general homelab Nix patterns
- **[bjw-s-labs](https://github.com/bjw-s-labs/nix-config)** — Module and service configuration patterns

---

## New Mac Setup

### Step 1

Install nix on a new mac [https://nixos.org/download/]

```bash
sh <(curl -L https://nixos.org/nix/install)
```
