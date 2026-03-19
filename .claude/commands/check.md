Run a full flake check on this nix-config repo and report results.

Steps:
1. Run `nix flake check --keep-going 2>&1` from the repo root.
2. If there are errors, show them clearly grouped by host/output.
3. For each error, suggest a likely fix based on the repo conventions:
   - Missing module imports → check `hosts/_modules/nixos/services/default.nix`
   - Type errors → check option definitions in the relevant module
   - Undefined variables → check `specialArgs` in `lib/mkSystem.nix`
4. If the check passes cleanly, confirm and suggest running a build for the target host.

Do not attempt to auto-fix errors — present findings and wait for direction.
