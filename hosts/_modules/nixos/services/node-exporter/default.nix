{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.modules.services.node-exporter;
in
{
  options.modules.services.node-exporter = {
    enable = lib.mkEnableOption "node-exporter";
    port = lib.mkOption {
      type = lib.types.int;
      default = 9100;
    };
    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Open the exporter port in the firewall";
    };
    enabledCollectors = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Collectors to enable on top of node-exporter's defaults";
    };
    systemdUnits = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [
        "sshd"
        "docker"
      ];
      description = ''
        Service names (without .service) the systemd collector exports.
        Empty exports every unit.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.prometheus.exporters.node = {
      enable = true;
      inherit (cfg) port openFirewall enabledCollectors;
      # node-exporter anchors this regex. [.] instead of \. because the flag
      # lands unquoted in ExecStart, where systemd would mangle a backslash.
      extraFlags = lib.optional (cfg.systemdUnits != [ ])
        "--collector.systemd.unit-include=(${lib.concatStringsSep "|" cfg.systemdUnits})[.]service";
    };
  };
}
