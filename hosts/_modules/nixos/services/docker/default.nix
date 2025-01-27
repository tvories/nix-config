{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.modules.services.podman;
in
{
  options.modules.services.docker = {
    enable = lib.mkEnableOption "docker";
  };

  config = lib.mkIf cfg.enable {
    virtualisation = {
      docker = {
        enable = true;
      };
    };
  };
}
