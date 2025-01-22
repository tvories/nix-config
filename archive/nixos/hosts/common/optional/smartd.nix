{ config, pkgs, lib, ... }:
{
  services.smartd = {
    enable = true;
    defaults = {
      # The default monitoring and alerting configuration
      monitored = "-a -o on -S on -n standby,q -s (S/../.././02|L/../../6/03) -W 4,35,40,!/dev/nvme0 -m ${config.networking.hostName}@t-vo.us";
    };
    notifications = {
      mail = {
        enable = true;
        mailer = "${pkgs.msmtp}/bin/msmtp";
        recipient = "${config.networking.hostName}@t-vo.us";
        sender = "${config.networking.hostName}@t-vo.us";
      };
    };
  };
  environment.systemPackages = [ pkgs.smartmontools ];
}
