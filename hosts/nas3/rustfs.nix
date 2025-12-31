{
  config,
  pkgs,
  lib,
  ...
}:

{
  # RustFS S3-compatible object storage
  # Based on: https://github.com/rustfs/rustfs
  config.virtualisation.oci-containers = {
    backend = "docker";
    containers = {
      rustfs = {
        image = "rustfs/rustfs:1.0.0-alpha.78";
        ports = [
          "9000:9000"  # S3 API
          "9001:9001"  # Console/Web UI
        ];
        autoStart = true;
        cmd = [
          "server"
          "/data"
          "--console-address"
          ":9001"
        ];
        environment = {
          # RustFS root credentials
          RUSTFS_ROOT_USER = "tadmin";
          RUSTFS_ROOT_PASSWORD = "changeme123";  # TODO: Move to sops secrets
        };
        volumes = [
          "/ook/minio:/data"
        ];
      };
    };
  };
}
