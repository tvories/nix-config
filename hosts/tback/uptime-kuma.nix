{ config, pkgs, lib, ...}:

{
  config.virtualisation.oci-containers = {
    backend = "docker";
    containers = {
      uptime-kuma = {
        image = "louislam/uptime-kuma:1.23.16-alpine";
        ports = [ "3001:3001" ];
      };
    };
  };
}