Deploy a nix-darwin host. The hostname is: $ARGUMENTS

Follow these steps:
1. Run `task nix:build-darwin host=$ARGUMENTS` to build and show the diff against the current system.
2. Display the build output and diff clearly. If the build fails, stop and report the error — do not proceed.
3. Ask the user to confirm before applying.
4. If confirmed, run `task nix:apply-darwin host=$ARGUMENTS` to switch.

Valid hostnames: DVA-YY669XDT42 (personal MacBook, aarch64-darwin), DVA-C02CQ7GCMD6T (work MacBook, x86_64-darwin)
Darwin deploys run locally on the target machine (not via SSH).
