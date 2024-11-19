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
  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      home.packages = [
        pkgs.unstable.fluxcd
      ];
      programs.fish = {
        interactiveShellInit = ''
          flux completion fish | source
        '';
      };
    })
  ];
}
