{ config, pkgs, lib, ... }:
{
  boot = {
    supportedFilesystems = [ "zfs" ];
    zfs = {
      forceImportRoot = false;
    };
  };

  services.zfs = {
    autoScrub.enable = true;
    trim.enable = true;
    zed = {
      settings = {
        ZED_DEBUG_LOG = "/tmp/zed.debug.log";
        ZED_EMAIL_ADDR= ["root"];
        ZED_EMAIL_PROG = "${pkgs.msmtp}/bin/msmtp";
        ZED_EMAIL_OPTS="-s '@SUBJECT@' @ADDRESS@ -r ${config.networking.hostName}@t-vo.us";
        ZED_NOTIFY_VERBOSE = true;
        ZED_NOTIFY_INTERVAL_SECS = 3600;
        ZED_USE_ENCLOSURE_LEDS = true;
        ZED_SCRUB_AFTER_RESILVER = true;
      };
    };
  };
}
