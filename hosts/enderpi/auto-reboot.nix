{pkgs, ...}:
{
  imports = [];
  systemd.timers.reboot-timer = {
    description = "Reboot the system daily at 6pm";
    timerConfig = {
      OnCalendar = "18:00";
      Persistent = true;
      Unit = "reboot-service.service";
    };
    wantedBy = [ "timers.target" ];
    partOf = [ "reboot-service.service" ];
  };

  systemd.services.reboot-service = {
    description = "Reboot the system daily at 6pm";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.systemd}/bin/systemctl reboot";
    };
  };
}