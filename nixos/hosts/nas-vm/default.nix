{ config, pkgs, lib, home-manager, sops-nix, ... }:

{
  imports = [
      # Host-specific
      ./hardware-configuration.nix
      ./disk-config.nix
      ./zfs.nix

      # Common imports
      ../common/nixos
      ../common/nixos/users/taylor
      ../common/nixos/users/tadmin
      ../common/nixos/users/service_accounts
      ../common/optional/fish.nix
      ../common/optional/k3s-server.nix
      ../common/optional/nfs-server.nix
      ../common/optional/samba-server.nix
      ../common/optional/zfs.nix
      ../common/optional/monitoring.nix
      ../common/optional/chrony.nix
      # ../common/optional/smartd.nix #! Does not work on a VM

      # Secrets
      
  ];

  # ! Local virtualbox config
  # networking = {
  #   hostName = "nixnas";
  #   hostId = "8023d2b9";
  #   networkmanager.enable = true;
  # };

  # # ! VMware config
  # networking = {
  #   hostName = "nas3vm";
  #   hostId = "8023d2b9";
  #   domain = "mcbadass.local";
  #   dhcpcd.enable = false;
  #   interfaces.ens192.ipv4.addresses = [{
  #     address = "192.168.1.230";
  #     prefixLength = 24;
  #   }];
  #   vlans = {
  #     vlan20 = { id=20; interface="ens192"; };
  #   };
  #   interfaces.vlan20.ipv4.addresses = [{
  #     address = "192.168.20.230";
  #     prefixLength = 24;
  #   }];
  #   defaultGateway = "192.168.1.1";
  #   nameservers = ["192.168.1.240" "192.168.1.241"];
  # };

  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID2+7PUnROyy7dALYGxsQSN16hz4iblHXtFJ6dHCUIBW"
  ];

  # ! Virtualbox Config
  networking = {
    hostName = "nas-vm";
    hostId = "8023d2b9";
    domain = "mcbadass.local";
    dhcpcd.enable = false;
    interfaces.enp0s3 = {
      ipv4.addresses = [{
        address = "192.168.1.230";
        prefixLength = 24;
      }];
      mtu = 9000;
    };
    vlans = {
      vlan20 = { id=20; interface="enp0s3"; };
      vlan80 = { id=80; interface="enp0s3"; };
    };
    interfaces.vlan20 = {
      ipv4.addresses = [{
        address = "192.168.20.230";
        prefixLength = 24;
      }];
      mtu = 9000;
    };
    interfaces.vlan80 = {
      ipv4.addresses = [{
        address = "192.168.80.230";
        prefixLength = 24;
      }];
      mtu = 9000;
    };
    defaultGateway = "192.168.1.1";
    nameservers = ["192.168.1.240" "192.168.1.241"];
  };

  sops.age.keyFile = "/var/lib/sops-nix/key.txt";

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
    devNodes = "/dev/disk/by-path";
    extraPools = [
      "ook"
    ];
  };

  # Samba config
  services.samba.shares = {
    Media = {
      path = "/ook/Media";
      browseable = "yes";
      "read only" = "no";
      "guest ok" = "yes";
    };
    Timey = {
      path = "/ook/Timey";
      browseable = "yes";
      "read only" = "no";
      "write list" = "taylor";
      "fruit:time machine" = "yes";
      "fruit:time machine max size" = "1050G";
      comment = "Time Machine Test";
      "create mask" = "0600";
      "directory mask" = "0700";
      "case sensitive" = "true";
      "default case" = "lower";
      "preserve case" = "no";
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
  system.stateVersion = "23.11"; # Did you read the comment?
}
