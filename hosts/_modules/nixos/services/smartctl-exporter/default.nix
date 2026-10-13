{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.modules.services.smartctl-exporter;
in
{
  options.modules.services.smartctl-exporter = {
    enable = lib.mkEnableOption "smartctl-exporter";
    port = lib.mkOption {
      type = lib.types.int;
      default = 9633;
    };
    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Open the exporter port in the firewall";
    };
    devices = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "/dev/disk/by-id/usb-EXAMPLE;sat" ];
      description = ''
        Devices to monitor, as `path` or `path;type` (type is passed to
        smartctl -d). Empty autodiscovers via smartctl --scan.
      '';
    };
    interval = lib.mkOption {
      type = lib.types.str;
      default = "60s";
      example = "6h";
      description = "Minimum time between smartctl queries per disk; cached data is served in between";
    };
    extraFlags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "--smartctl.powermode-check=never" ];
      description = "Extra smartctl_exporter flags";
    };
  };

  config = lib.mkIf cfg.enable {
    services.prometheus.exporters.smartctl = {
      enable = true;
      inherit (cfg) port openFirewall devices extraFlags;
      maxInterval = cfg.interval;
    };
  };
}
