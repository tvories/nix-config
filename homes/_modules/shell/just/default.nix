{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.modules.shell.just;
in
{
  options.modules.shell.just = {
    enable = lib.mkEnableOption "just";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.just ];
  };
}
