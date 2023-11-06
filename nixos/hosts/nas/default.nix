{ config, pkgs, lib, home-manager, ... }:

{
  imports = [
      # Host-specific hardware
      ./hardware-configuration.nix

      # Common imports
      ../common/nixos
      ../common/nixos/users/taylor
      ../common/nixos/users/tadmin
      ../common/optional/fish.nix
      ../common/optional/k3s-server.nix
      ../common/optional/nfs-server.nix
      ../common/optional/virtualbox.nix
      ../common/optional/samba-server.nix
      ../common/optional/starship.nix
      ../common/optional/smartd.nix
      ../common/optional/zfs.nix
      # ../common/optional/monitoring.nix
  ];

  networking = {
    hostName = "nas3";
    hostId = "824119dfs";
    networkmanager.enable = true;
  };

  # User config
  users.users = {
    taylor = {
      isNormalUser = true;
      extraGroups = [
        "samba-users"
      ];
    };
  };

  # Group config
  users.groups = {
    external-services = {
      gid = 65542;
    };
    admins = {
      members = ["taylor"];
    };
  };

  # Packages
  environment.systemPackages = [
    pkgs.rclone
  ];

  # ZFS config
  boot.zfs = {
    extraPools = [
      "ook"
    ];
  };

  # Samba config
  services.samba.shares = {
    Backup = {
      path = "/ook/Backup";
      "read only" = "no";
    };
    Media = {
      path = "/ook/Media";
      "read only" = "no";
    };
    Documents = {
      path = "/ook/Documents";
      "read only" = "no";
    };
    Music = {
      path = "/ook/Music";
      "read only" = "no";
    };
  };

  # may fix issues with network service failing during a nixos-rebuild
  systemd.services.NetworkManager-wait-online.enable = lib.mkForce false;
  systemd.services.systemd-networkd-wait-online.enable = lib.mkForce false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
