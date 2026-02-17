{
  config,
  pkgs,
  lib,
  ...
}:

{
  config = {
    # Configure sops secret for zerobyte
    sops.secrets.zerobyte-app-secret = {
      sopsFile = ./secrets.sops.yaml;
    };

    # Create environment file with secrets
    sops.templates."zerobyte.env".content = ''
      APP_SECRET=${config.sops.placeholder.zerobyte-app-secret}
    '';

    virtualisation.oci-containers = {
      backend = "docker";
      containers = {
        zerobyte = {
          image = "ghcr.io/nicotsx/zerobyte:v0.28.2";
          ports = [ "4096:4096" ];
          autoStart = true;
          environment = {
            TZ = "America/Denver";
            BASE_URL = "https://zerobyte.t-vo.us";
          };
          environmentFiles = [
            config.sops.templates."zerobyte.env".path
          ];
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
