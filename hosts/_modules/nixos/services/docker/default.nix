{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.modules.services.docker;
in
{
  options.modules.services.docker = {
    enable = lib.mkEnableOption "docker";
  };

  config = lib.mkIf cfg.enable {
    virtualisation = {
      docker = {
        enable = true;
        package = pkgs.docker_29;
        # Every image bump leaves the old version behind; --all removes
        # unused tagged images, not just dangling layers. Volumes untouched.
        autoPrune = {
          enable = true;
          dates = "weekly";
          flags = [ "--all" ];
        };
      };
    };
  };
}
