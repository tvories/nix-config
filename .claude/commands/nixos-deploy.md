Deploy a NixOS host. The hostname is: $ARGUMENTS

Follow these steps:
1. Run `just nix build-nixos $ARGUMENTS` to build and show the diff against the current system.
2. Display the build output and diff clearly. If the build fails, stop and report the error — do not proceed.
3. Ask the user to confirm before applying.
4. If confirmed, run `just nix apply-nixos $ARGUMENTS` to switch. For `tback` (slow RPi), use `just nix apply-nixos-local tback` instead, which builds on this machine.

Valid hostnames: nas3, nas-vm, tback, homebox, wsl
Remote targets resolve as `taylor@<hostname>.mcbadass.local` via SSH.
