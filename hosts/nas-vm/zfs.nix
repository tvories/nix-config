{ config, lib, pkgs, modulesPath, ... }:
{
  # ZFS Replication
  services.zrepl = {
    enable = true;
    settings = {
      global = {
        logging = [
          {
            type = "syslog";
            format = "human";
            level = "warn";
          }
        ];
        monitoring = [
          {
            type = "prometheus";
            listen = ":9811";
            listen_freebind = true;
          }
        ];
      };

      jobs = [
        {
          # This rule creates snapshots at the top zpool level daily. I may want to fine-tune this
          # I definitely want to fine tune replication
          name = "daily";
          type = "snap";
          filesystems = {
            "ook<" = true;
          };
          snapshotting = {
            type = "cron";
            cron = "0 3 * * *";
            prefix = "zrepl_daily_";
            timestamp_format = "dense";
          };
          pruning = {
            keep = [
              {
                type = "last_n";
                count = 7;
              }
            ];
          };
        }
      ];
    };

              # regex: "^zrepl_daily_.*$"
  };
}