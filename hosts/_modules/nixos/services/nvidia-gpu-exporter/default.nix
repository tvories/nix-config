# NVIDIA GPU metrics for Prometheus (utilisation, memory, temperature, power,
# clocks), read from nvidia-smi. NixOS has no exporter module for it.
{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.modules.services.nvidia-gpu-exporter;
in
{
  options.modules.services.nvidia-gpu-exporter = {
    enable = lib.mkEnableOption "nvidia-gpu-exporter";
    port = lib.mkOption {
      type = lib.types.port;
      default = 9835;
    };
    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Open the exporter port in the firewall";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.nvidia-gpu-exporter = {
      description = "Prometheus exporter for NVIDIA GPUs";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      serviceConfig = {
        # nvidia-smi from the running driver: one from another driver version
        # refuses to talk to the kernel module.
        ExecStart = lib.concatStringsSep " " [
          (lib.getExe pkgs.prometheus-nvidia-gpu-exporter)
          "--web.listen-address=:${toString cfg.port}"
          "--nvidia-smi-command=${lib.getExe' config.hardware.nvidia.package.bin "nvidia-smi"}"
        ];
        DynamicUser = true;
        # The /dev/nvidia* nodes are world-accessible, so no extra group.
        Restart = "on-failure";
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        NoNewPrivileges = true;
      };
    };

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.port ];
  };
}
