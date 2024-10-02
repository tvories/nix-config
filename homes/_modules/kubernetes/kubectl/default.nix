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
      programs.fish = {
        shellAliases = {
          k = "kubectl";
        };
      };
      home.packages = [
        pkgs.kubecolor
        pkgs.kubectl
      ];
    })
  ];
}
