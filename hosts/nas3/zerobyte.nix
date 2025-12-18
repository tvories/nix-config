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
        restart = "unless-stopped";
        environment = [
          "TZ=America/Denver"
        ];
        volumes = [
          "/etc/localtime:/etc/localtime:ro"
          "/var/lib/zerobyte:/var/lib/zerobyte"
          "/ook/minio:/mydata/minio"
        ];
      };
    };
  };
}
