{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.modules.services.zfs-exporter;
in
{
  options.modules.services.zfs-exporter = {
    enable = lib.mkEnableOption "zfs-exporter";
    port = lib.mkOption {
      type = lib.types.int;
      default = 9901;
    };
  };

  config = lib.mkIf cfg.enable {
    services.prometheus.exporters.smartctl = {
      enable = true;
      inherit (cfg) port;
    };
  };
}
