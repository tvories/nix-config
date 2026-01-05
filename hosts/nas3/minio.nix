{
  config,
  pkgs,
  lib,
  ...
}:

{
  config = {
    sops.templates."minio.env".content = ''
      
            MINIO_ROOT_USER=${config.sops.placeholder.RUSTFS_ACCESS_KEY}
            MINIO_ROOT_PASSWORD=${config.sops.placeholder.RUSTFS_SECRET_KEY}
    '';

    virtualisation.oci-containers = {
      backend = "docker";
      containers = {
        minio = {
          image = "minio/minio:RELEASE.2025-04-22T22-12-26Z";
          cmd = [
            "server"
            "/data"
            "--console-address"
            ":9001"
          ];
          ports = [
            "19010:9000" # S3 API
            "19011:9001" # Console/Web UI
          ];
          autoStart = true;
          environmentFiles = [
            config.sops.templates."minio.env".path
          ];
          volumes = [
            "/ook/minio:/data"
          ];
        };
      };
    };

    modules.services.traefik.routers.minio-src-api = {
      rule = "Host(`minio-src.nas.t-vo.us`)";
      service = "minio-src-api";
    };

    modules.services.traefik.routers.minio-src-console = {
      rule = "Host(`minio-src-console.nas.t-vo.us`)";
      service = "minio-src-console";
    };

    modules.services.traefik.services.minio-src-api = {
      url = "http://localhost:19010";
    };

    modules.services.traefik.services.minio-src-console = {
      url = "http://localhost:19011";
    };
  };
}
