{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.modules.shell.gcloud;
  gdk = pkgs.google-cloud-sdk.withExtraComponents( with pkgs.google-cloud-sdk.components; [
    gke-gcloud-auth-plugin
  ]);
in {
  options.modules.shell.gcloud = {
    enable = lib.mkEnableOption "gcloud";
    package = lib.mkPackageOption pkgs "gdk" { };
  };
  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      home.packages = [
        gdk
      ];
      programs = {
        fish.shellInit = lib.mkAfter ''
          complete -c gcloud -f -a '(__fish_argcomplete_complete gcloud)'
          complete -c gsutil -f -a '(__fish_argcomplete_complete gsutil)'
        '';
      };
    })
  ];
}
