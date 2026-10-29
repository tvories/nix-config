{ lib, ... }:
{
  disko.devices = {
    disk.main = {
      # The fitlet2's M.2 2242 SATA SSD. It enumerates as /dev/sdX alongside
      # the USB installer, so install-felix picks the disk at runtime and
      # overrides this (hosts/felix/installer.nix). The installed system
      # mounts by partition label, so this path is only used for formatting.
      device = lib.mkDefault "/dev/disk/by-id/ata-NGFF_2242_64GB_SSD_2020122500731";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          esp = {
            name = "ESP";
            type = "EF00";
            # Room for plenty of generations (homebox's 99M ESP ran out).
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
