# Offline USB installer for a host: a NixOS live ISO carrying the host's
# complete, prebuilt system and disko scripts, so installing needs no network
# or builds.
#
#   just nix build-installer <host>   # then write the ISO to a USB stick
#   boot the machine from it, then:   sudo install-<host> [/dev/disk]
#
# `target` is the host's nixosConfiguration and `diskTransports` the buses
# (lsblk TRAN) its install disk can be on; both are passed in from flake.nix.
{
  lib,
  pkgs,
  modulesPath,
  target,
  diskTransports,
  ...
}:
let
  inherit (target.config.networking) hostName;
  # Disk names depend on what's plugged in (the USB stick is /dev/sdX too), so
  # the disko scripts point at a symlink that the install script creates once
  # the target disk is chosen. Only formatting uses it; the installed system
  # mounts by partition label.
  targetLink = "/dev/${hostName}-target";
  diskoBuild =
    (target.extendModules {
      modules = [ { disko.devices.disk.main.device = lib.mkForce targetLink; } ];
    }).config.system.build;
  inherit (target.config.system.build) toplevel;
  isCandidate = lib.concatMapStringsSep " || " (t: ''$2 == "${t}"'') diskTransports;

  installHost = pkgs.writeShellApplication {
    name = "install-${hostName}";
    runtimeInputs = with pkgs; [
      util-linux
      gptfdisk
      gawk
    ];
    text = ''
      if [ "$(id -u)" -ne 0 ]; then
        echo "Run as root: sudo install-${hostName} [/dev/disk]" >&2
        exit 1
      fi

      # The disk this live system booted from, so it's never offered.
      boot_src=$(findmnt -no SOURCE /iso 2>/dev/null || true)
      boot_disk=""
      if [ -n "$boot_src" ]; then
        boot_disk=/dev/$(lsblk -no PKNAME "$boot_src" | head -1)
      fi

      if [ $# -ge 1 ]; then
        disk=$(readlink -f "$1")
      else
        # Internal, non-removable disks on the host's install buses, other
        # than the USB stick.
        mapfile -t candidates < <(
          lsblk -dpno NAME,TRAN,RM | awk '(${isCandidate}) && $3 == 0 { print $1 }' |
            grep -vxF "''${boot_disk:-none}" || true
        )
        if [ ''${#candidates[@]} -ne 1 ]; then
          echo "Expected exactly one internal ${lib.concatStringsSep "/" diskTransports} disk, found ''${#candidates[@]}:" >&2
          lsblk -d -o NAME,SIZE,TRAN,RM,MODEL >&2
          echo "Re-run with the disk to use, e.g.: sudo install-${hostName} /dev/disk/by-id/..." >&2
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

      lsblk -o NAME,SIZE,TRAN,MODEL,FSTYPE,LABEL,MOUNTPOINTS
      echo
      echo "Target: $disk  $(lsblk -dno SIZE,MODEL "$disk")"
      for id in /dev/disk/by-id/*; do
        [ "$(readlink -f "$id")" = "$disk" ] && echo "  by-id: $id"
      done
      echo "This ERASES $disk and installs ${hostName}."
      read -rp "Type '${hostName}' to continue: " answer
      [ "$answer" = ${hostName} ] || { echo "Aborted."; exit 1; }

      ln -sfn "$disk" ${targetLink}
      # Clear any previous partition table so disko starts from a blank disk.
      wipefs -af "$disk"
      sgdisk --zap-all "$disk"
      ${diskoBuild.formatScript}
      ${diskoBuild.mountScript}

      nixos-install --system ${toplevel} --no-root-passwd --no-channel-copy
      echo
      echo "Installed. Remove the USB drive and reboot."
      echo "Then set disko.devices.disk.main.device in hosts/${hostName}/disk-config.nix to the by-id path above."
    '';
  };
in
{
  imports = [ (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix") ];

  nixpkgs.hostPlatform = "x86_64-linux";

  # Puts the host's whole closure on the ISO, so nixos-install copies from the
  # stick instead of downloading.
  isoImage.storeContents = [
    toplevel
    diskoBuild.formatScript
    diskoBuild.mountScript
  ];

  environment.systemPackages = [ installHost ];

  services.getty.helpLine = lib.mkAfter ''

    To install ${hostName} (erases the chosen disk): sudo install-${hostName}
  '';

  # Lets the install also be driven over SSH from another machine.
  users.users.root.openssh.authorizedKeys.keys = lib.strings.splitString "\n" (
    builtins.readFile ../../homes/taylor/config/ssh/ssh.pub
  );
}
