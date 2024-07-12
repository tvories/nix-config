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
  };
  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      home.packages = [
        gdk
      ];
    })
  ];
}
