{ lib, ... }:
{
  disko.devices = {
    disk.main = {
      # The Intel 660p 1TB NVMe (the old Windows install, G: in Windows). By
      # id, because nvme0n1 is the Windows 980 PRO on this board. The installed
      # system mounts by partition label, so this path is only used for
      # formatting; install-deskmonster can still override it (hosts/_installer).
      device = lib.mkDefault "/dev/disk/by-id/nvme-INTEL_SSDPEKNW010T8_BTNH90340BRT1P0B";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          # Its own ESP, so Windows' boot partition on the 980 PRO is never
          # touched; pick the OS from the firmware boot menu (F11).
          esp = {
            name = "ESP";
            type = "EF00";
            size = "1G";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };
          root = {
            name = "root";
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };
        };
      };
    };
  };
}
