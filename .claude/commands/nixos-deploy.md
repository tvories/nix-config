Deploy a NixOS host. The hostname is: $ARGUMENTS

Follow these steps:
1. Run `task nix:build-nixos host=$ARGUMENTS` to build and show the diff against the current system.
2. Display the build output and diff clearly. If the build fails, stop and report the error — do not proceed.
3. Ask the user to confirm before applying.
4. If confirmed, run `task nix:apply-nixos host=$ARGUMENTS` to switch.

Valid hostnames: nas3, nas-vm, tback, homebox, wsl
Remote targets resolve as `taylor@<hostname>.mcbadass.local` via SSH.
