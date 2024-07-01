{pkgs, ...}:
{
  imports = [];
  systemd.timers.reboot-timer = {
    description = "Reboot the system daily at 6pm";
    timerConfig = {
      OnCalendar = "18:00";
      Persistent = true;
    };
    wantedBy = [ "timers.target" ];
  };

  systemd.services.reboot-service = {
    description = "Reboot the system";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.systemd}/bin/systemctl reboot";
    };
  };
}