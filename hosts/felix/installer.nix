# Offline USB installer for felix: a NixOS live ISO carrying felix's complete,
# prebuilt system and disko scripts, so installing needs no network or builds.
#
#   just nix build-installer felix   # then write the ISO to a USB stick
#   boot the fitlet2 from it, then:  sudo install-felix [/dev/sdX]
#
# `target` is felix's nixosConfiguration, passed in from flake.nix.
{
  lib,
  pkgs,
  modulesPath,
  target,
  ...
}:
let
  # The SSD and the USB stick are both /dev/sdX, so the disko scripts point at
  # a symlink that install-felix creates once the target disk is chosen. Only
  # formatting uses it; the installed system mounts by partition label.
  targetLink = "/dev/felix-target";
  diskoBuild =
    (target.extendModules {
      modules = [ { disko.devices.disk.main.device = lib.mkForce targetLink; } ];
    }).config.system.build;
  inherit (target.config.system.build) toplevel;

  installFelix = pkgs.writeShellApplication {
    name = "install-felix";
    runtimeInputs = with pkgs; [
      util-linux
      gptfdisk
      gawk
    ];
    text = ''
      if [ "$(id -u)" -ne 0 ]; then
        echo "Run as root: sudo install-felix [/dev/sdX]" >&2
        exit 1
      fi

      # The disk this live system booted from, so it's never offered.
      boot_src=$(findmnt -no SOURCE /iso 2>/dev/null || true)
      boot_disk=""
      if [ -n "$boot_src" ]; then
        boot_disk=/dev/$(lsblk -no PKNAME "$boot_src" | head -1)
      fi

      if [ $# -ge 1 ]; then
        disk=$1
      else
        # Internal, non-removable SATA/NVMe disks other than the USB stick.
        mapfile -t candidates < <(
          lsblk -dpno NAME,TRAN,RM | awk '($2 == "sata" || $2 == "nvme") && $3 == 0 { print $1 }' |
            grep -vxF "''${boot_disk:-none}" || true
        )
        if [ ''${#candidates[@]} -ne 1 ]; then
          echo "Expected exactly one internal SATA/NVMe disk, found ''${#candidates[@]}:" >&2
          lsblk -d -o NAME,SIZE,TRAN,RM,MODEL >&2
          echo "Re-run with the disk to use, e.g.: sudo install-felix /dev/sda" >&2
          exit 1
        fi
        disk=''${candidates[0]}
      fi

      if [ ! -b "$disk" ]; then
        echo "$disk is not a block device" >&2
        exit 1
      fi
      if [ "$disk" = "$boot_disk" ]; then
        echo "$disk is the USB stick this installer is running from" >&2
        exit 1
      fi

      lsblk -o NAME,SIZE,TRAN,MODEL,MOUNTPOINTS
      echo
      echo "Target: $disk  $(lsblk -dno SIZE,MODEL "$disk")"
      for id in /dev/disk/by-id/*; do
        [ "$(readlink -f "$id")" = "$disk" ] && echo "  by-id: $id"
      done
      echo "This ERASES $disk and installs felix."
      read -rp "Type 'felix' to continue: " answer
      [ "$answer" = felix ] || { echo "Aborted."; exit 1; }

      ln -sfn "$disk" ${targetLink}
      # Clear any previous partition table so disko starts from a blank disk.
      wipefs -af "$disk"
      sgdisk --zap-all "$disk"
      ${diskoBuild.formatScript}
      ${diskoBuild.mountScript}

      nixos-install --system ${toplevel} --no-root-passwd --no-channel-copy
      echo
      echo "Installed. Remove the USB drive and reboot."
      echo "Then set disko.devices.disk.main.device in hosts/felix/disk-config.nix to the by-id path above."
    '';
  };
in
{
  imports = [ (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix") ];

  nixpkgs.hostPlatform = "x86_64-linux";

  # Puts felix's whole closure on the ISO, so nixos-install copies from the
  # stick instead of downloading.
  isoImage.storeContents = [
    toplevel
    diskoBuild.formatScript
    diskoBuild.mountScript
  ];

  environment.systemPackages = [ installFelix ];

  services.getty.helpLine = lib.mkAfter ''

    To install felix (erases the internal SSD): sudo install-felix
  '';

  # Lets the install also be driven over SSH from another machine.
  users.users.root.openssh.authorizedKeys.keys = lib.strings.splitString "\n" (
    builtins.readFile ../../homes/taylor/config/ssh/ssh.pub
  );
}
