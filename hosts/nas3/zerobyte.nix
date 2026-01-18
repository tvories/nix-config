{
  config,
  pkgs,
  lib,
  ...
}:

{
  config = {
    virtualisation.oci-containers = {
      backend = "docker";
      containers = {
        zerobyte = {
          image = "ghcr.io/nicotsx/zerobyte:v0.22.0";
          ports = [ "4096:4096" ];
          autoStart = true;
          environment = {
            TZ = "America/Denver";
          };
          volumes = [
            "/etc/localtime:/etc/localtime:ro"
            "/var/lib/zerobyte:/var/lib/zerobyte"
            "/ook/minio:/mydata/minio"
            "/ook/Photos:/mydata/Photos"
            "/ook/Documents:/mydata/Documents"
            "/ook/k8s:/mydata/k8s"
            "/ook/Backup:/mydata/Backup"
            "/ook/rustfs:/mydata/rustfs"
          ];
        };
      };
    };

    # Traefik configuration for zerobyte
    modules.services.traefik.routers.zerobyte = {
      rule = "Host(`zerobyte.t-vo.us`)";
      service = "zerobyte";
    };

    modules.services.traefik.services.zerobyte = {
      url = "http://localhost:4096";
    };
  };
}
