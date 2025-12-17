{
  config,
  pkgs,
  lib,
  ...
}:

{
  config.virtualisation.oci-containers = {
    backend = "docker";
    containers = {
      zerobyte = {
        image = "ghcr.io/nicotsx/zerobyte:v0.19";
        ports = [ "4096:4096" ];
      };
    };
  };
}
