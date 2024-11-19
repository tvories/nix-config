{
  pkgs,
  lib,
  config,
  hostname,
  ...
}:
let
  ifGroupsExist = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
in
{
  imports = [
    # Host-specific
    ./hardware-configuration.nix
    ./disk-config.nix
    # ./secrets.nix

    #TODO: Old config
    # ./zfs.nix

    # # Common imports
    # ../common/nixos
    # ../common/nixos/users/taylor
    # ../common/nixos/users/tadmin
    # ../common/nixos/users/kate
    # ../common/nixos/users/service_accounts
    # ../common/optional/fish.nix
    # ../common/optional/k3s-server.nix
    # ../common/optional/nfs-server.nix
    # ../common/optional/samba-server.nix
    # ../common/optional/zfs.nix
    # ../common/optional/monitoring.nix
    # ../common/optional/chrony.nix
    # # ../common/optional/smartd.nix #! Does not work on a VM

    # # Secrets
  ];

  config = {
    # ! Virtualbox Config
    networking = {
      firewall.enable = false;
      hostName = hostname;
      hostId = "8023d2b9";
      domain = "mcbadass.local";
      dhcpcd.enable = false;
      interfaces.enp0s3 = {
        ipv4.addresses = [
          {
            address = "192.168.1.230";
            prefixLength = 24;
          }
        ];
        mtu = 9000;
      };
      vlans = {
        vlan20 = {
          id = 20;
          interface = "enp0s3";
        };
        vlan80 = {
          id = 80;
          interface = "enp0s3";
        };
      };
      interfaces.vlan20 = {
        ipv4.addresses = [
          {
            address = "192.168.20.230";
            prefixLength = 24;
          }
        ];
        mtu = 9000;
      };
      interfaces.vlan80 = {
        ipv4.addresses = [
          {
            address = "192.168.80.230";
            prefixLength = 24;
          }
        ];
        mtu = 9000;
      };
      defaultGateway = "192.168.1.1";
      nameservers = [
        "192.168.1.240"
        "192.168.1.241"
      ];
    };
    users.users.taylor = {
      uid = 1000;
      name = "taylor";
      home = "/home/taylor";
      group = "taylor";
      shell = pkgs.fish;
      openssh.authorizedKeys.keys = lib.strings.splitString "\n" (
        builtins.readFile ../../homes/taylor/config/ssh/ssh.pub
      );
      initialHashedPassword = "$y$j9T$hbT0Eeox2XSgwlFIaxEmh.$PBtYZ0w1M9.rGbKBYz8MEo.59Sv3gFwJdxS4BI7G7S5";
      isNormalUser = true;
      extraGroups =
        [
          "wheel"
          "users"
        ]
        ++ ifGroupsExist [
          "network"
          "samba-users"
        ];
    };
    users.groups.taylor = {
      gid = 1000;
    };

    system.activationScripts.postActivation.text = ''
      # Must match what is in /etc/shells
      chsh -s /run/current-system/sw/bin/fish taylor
    '';

    modules = {
      filesystems.zfs = {
        enable = true;
        mountPoolsAtBoot = [ "ook" ];
      };

      services = {
        nfs.enable = true;
        node-exporter.enable = true;
        zfs-exporter.enable = true;
        openssh.enable = true;
        msmtp.enable = true;

        samba = {
          enable = true;
          shares = {
            Media = {
              path = "/ook/Media";
              browseable = "yes";
              "read only" = "no";
              "guest ok" = "yes";
            };
            Timey = {
              path = "/ook/Timey";
              "read only" = "no";
              "fruit:aapl" = "yes";
              "fruit:time machine" = "yes";
            };
          };
        };

        # * Note: doesn't work on a VM
        # smartd.enable = true;
        # smartctl-exporter.enable = true;
        k3s = {
          enable = true;
          extraFlags = [
            "--tls-san"
            "nas.mcbadass.local"
            "--flannel-backend=vxlan"
            "--disable-network-policy"
          ];
        };
      };

      users = {
        additionalUsers = {
          kate = {
            isNormalUser = true;
            extraGroups = ifGroupsExist [ "samba-users" ];
          };
          svc_scanner = {
            isSystemUser = true;
            group = "svc_scanner";
            extraGroups = ifGroupsExist [
              "samba-users"
              "docs-rw"
            ];
          };
        };
        groups = {
          svc_scanner = { };
          backup-rw = {
            gid = 65541;
            members = [ "taylor" ];
          };
          admins = {
            gid = 991;
            members = [ "taylor" ];
          };
          docs-rw = {
            gid = 65543;
            members = [ "taylor" ];
          };
          media-rw = {
            gid = 65539;
            members = [ "taylor" ];
          };
        };
      };
    };
    # boot.loader = {
    #   systemd-boot.enable = true;
    #   efi.canTouchEfiVariables = true;
    # };
  };

  # # ZFS config
  # boot.zfs = {
  #   devNodes = "/dev/disk/by-path";
  #   extraPools = [
  #     "ook"
  #   ];
  # };

  # # Samba config
  # services.samba.shares = {
  #   Media = {
  #     path = "/ook/Media";
  #     browseable = "yes";
  #     "read only" = "no";
  #     "guest ok" = "yes";
  #   };
  #   Timey = {
  #     path = "/ook/Timey";
  #     browseable = "yes";
  #     "read only" = "no";
  #     "write list" = "taylor";
  #     "fruit:time machine" = "yes";
  #     "fruit:time machine max size" = "1050G";
  #     comment = "Time Machine Test";
  #     "create mask" = "0600";
  #     "directory mask" = "0700";
  #     "case sensitive" = "true";
  #     "default case" = "lower";
  #     "preserve case" = "no";
  #   };
  # };

  # may fix issues with network service failing during a nixos-rebuild
  # systemd.services.NetworkManager-wait-online.enable = lib.mkForce false;
  # systemd.services.systemd-networkd-wait-online.enable = lib.mkForce false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  # system.stateVersion = "24.05"; # Did you read the comment?
}
