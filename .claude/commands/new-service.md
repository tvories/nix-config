Scaffold a new NixOS service module for this repo. The service name is: $ARGUMENTS

Follow these steps:

1. Create `hosts/_modules/nixos/services/$ARGUMENTS/default.nix` using this exact pattern:

```nix
{ lib, config, pkgs, ... }:
let
  cfg = config.modules.services.$ARGUMENTS;
in
{
  options.modules.services.$ARGUMENTS = {
    enable = lib.mkEnableOption "$ARGUMENTS";
  };

  config = lib.mkIf cfg.enable {
    # TODO: implement $ARGUMENTS service config here
  };
}
```

2. Add `./\$ARGUMENTS` to the imports list in `hosts/_modules/nixos/services/default.nix`.

3. Show the user a summary of what was created and remind them to:
   - Enable the service on a host with `modules.services.$ARGUMENTS.enable = true;`
   - Add any SOPS secrets needed: `sops.secrets.<name> = { sopsFile = ./secret.sops.yaml; };`
   - Run `task nix:build-nixos host=<hostname>` to validate before deploying

Do NOT enable the module on any host — leave that to the user.
