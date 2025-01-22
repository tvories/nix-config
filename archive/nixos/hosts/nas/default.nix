{ config, pkgs, lib, home-manager, ... }:

{
  imports = [
      # Host-specific
      ./hardware-configuration.nix
      ./disk-config.nix
      ./zfs.nix
      ./restic.nix

      # Common imports
      ../common/nixos
      ../common/nixos/users/taylor
      ../common/nixos/users/tadmin
      ../common/nixos/users/kate
      ../common/nixos/users/service_accounts
      ../common/optional/fish.nix
      ../common/optional/k3s-server.nix
      ../common/optional/nfs-server.nix
      ../common/optional/samba-server.nix
      ../common/optional/zfs.nix
      ../common/optional/monitoring.nix
      ../common/optional/smartd.nix
      ../common/optional/chrony.nix
  ];

  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID2+7PUnROyy7dALYGxsQSN16hz4iblHXtFJ6dHCUIBW"
  ];
  networking.firewall.enable = false;

  networking = {
    hostName = "nas3";
    hostId = "8023d2b9";
    domain = "mcbadass.local";
    dhcpcd.enable = false;
    interfaces.enp1s0 = {
      ipv4.addresses = [{
        address = "192.168.1.24";
        prefixLength = 24;
      }];
      mtu = 9000;
    };
    vlans = {
      vlan20 = { id=20; interface="enp1s0"; };
      vlan60 = { id=60; interface="enp1s0"; };
      vlan80 = { id=80; interface="enp1s0"; };
    };
    interfaces.vlan20 = {
      ipv4.addresses = [{
        address = "192.168.20.24";
        prefixLength = 24;
      }];
      mtu = 9000;
    };
    interfaces.vlan60 = {
      ipv4.addresses = [{
        address = "192.168.60.24";
        prefixLength = 24;
      }];
      mtu = 9000;
    };
    interfaces.vlan80 = {
      ipv4.addresses = [{
        address = "192.168.80.24";
        prefixLength = 24;
      }];
      mtu = 9000;
    };
    defaultGateway = "192.168.1.1";
    nameservers = ["192.168.1.240" "192.168.1.241"];
  };

  nixpkgs.config.permittedInsecurePackages = [
    "vault-1.14.10"
  ];

  # Group config
  users.groups = {
    backup-rw = {
      gid = 65541;
      members = ["taylor"];
    };
    docs-rw = {
      gid = 65543;
      members = ["taylor"];
    };
    media-rw = {
      gid = 65539;
      members = ["taylor"];
    };
  };

  # ZFS config
  boot.zfs = {
    devNodes = "/dev/disk/by-id";
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
    paperless_inbox = {
      path = "/ook/k8s/paperless/consume";
      "read only" = "no";
    };
    # Music = {
    #   path = "/ook/Media/music";
    #   "read only" = "no";
    # };
    Photos = {
      path = "/ook/Photos";
      "read only" = "no";
    };
    TimeMachineWork = {
      path = "/ook/TimeMachine/work";
      # "writable" = "yes";
      # "durable handles" = "yes";
      # "kernel oplocks" = "no";
      # "kernel share modes" = "no";
      # "posix locking" = "no";
      "vfs objects" = "acl_xattr catia fruit streams_xattr";
      browseable = "yes";
      "read only" = "no";
      "fruit:time machine" = "yes";
      # "fruit:metadata" = "stream";
      # "fruit:locking" = "netatalk";
      # "fruit:time machine max size" = "1.9T";
      comment = "Work Macbook Time Machine";
      # "create mask" = "0600";
      # "directory mask" = "0700";
      # "case sensitive" = "true";
      # "default case" = "lower";
      # "preserve case" = "no";
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
  system.stateVersion = "24.05"; # Did you read the comment?
}
