{
  config,
  pkgs,
  lib,
  ...
}:

{
  # RustFS S3-compatible object storage
  # Based on: https://github.com/rustfs/rustfs

  config = {
    # Configure sops secrets
    sops.secrets.rustfs-root-user = {
      sopsFile = ./secrets.sops.yaml;
    };
    sops.secrets.rustfs-root-password = {
      sopsFile = ./secrets.sops.yaml;
    };
    sops.secrets.RUSTFS_ACCESS_KEY = {
      sopsFile = ./secrets.sops.yaml;
    };
    sops.secrets.RUSTFS_SECRET_KEY = {
      sopsFile = ./secrets.sops.yaml;
    };

    # Create environment file with secrets
    sops.templates."rustfs.env".content = ''
      RUSTFS_ROOT_USER=${config.sops.placeholder.rustfs-root-user}
      RUSTFS_ROOT_PASSWORD=${config.sops.placeholder.rustfs-root-password}
      RUSTFS_ACCESS_KEY=${config.sops.placeholder.RUSTFS_ACCESS_KEY}
      RUSTFS_SECRET_KEY=${config.sops.placeholder.RUSTFS_SECRET_KEY}
      RUSTFS_VOLUMES=/data
      RUSTFS_CONSOLE_ENABLE=true
    '';

    virtualisation.oci-containers = {
      backend = "docker";
      containers = {
        rustfs = {
          image = "rustfs/rustfs:1.0.0-alpha.78";
          ports = [
            "9000:9000"  # S3 API
            "9001:9001"  # Console/Web UI
          ];
          autoStart = true;
          environmentFiles = [
            config.sops.templates."rustfs.env".path
          ];
          volumes = [
            "/ook/rustfs:/data"
          ];
        };
      };
    };

    # Traefik configuration for rustfs
    modules.services.traefik.routers.rustfs-api = {
      rule = "Host(`s3.nas.t-vo.us`)";
      service = "rustfs-api";
    };

    modules.services.traefik.routers.rustfs-console = {
      rule = "Host(`minio.nas.t-vo.us`)";
      service = "rustfs-console";
    };

    modules.services.traefik.services.rustfs-api = {
      url = "http://localhost:9000";
    };

    modules.services.traefik.services.rustfs-console = {
      url = "http://localhost:9001";
    };
  };
}
