{ config, pkgs, lib, ... }:

{
  services.prometheus.exporters = {
    node = {
      enable = true;
      enabledCollectors = [
        "diskstats"
        "filesystem"
        "loadavg"
        "meminfo"
        "netdev"
        "stat"
        "time"
        "uname"
        "systemd"
      ];
    };
    zfs = {
      enable = true;
    };
    smartctl = {
      enable = true;
    };
  };
}