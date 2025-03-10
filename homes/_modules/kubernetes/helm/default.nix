{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.modules.kubernetes;
in
{
  config = lib.mkMerge [ (lib.mkIf cfg.enable { home.packages = [ pkgs.helm ]; }) ];
}
