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
    # ./zfs.nix
    # ./zerobyte.nix
    # ./minio.nix
    # ./rustfs.nix

    #TODO: Old config
    # Common imports
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
    # ../common/optional/smartd.nix
    # ../common/optional/chrony.nix
  ];

  config = {
    nix.settings.trusted-users = [
      "root"
      "@wheel"
    ];
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
        vlan60 = {
          id = 60;
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
      interfaces.vlan60 = {
        ipv4.addresses = [
          {
            address = "192.168.60.230";
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
      extraGroups = [
        "wheel"
        "users"
      ]
      ++ ifGroupsExist [
        "network"
        "samba-users"
        "docker"
      ];
    };
    users.groups.taylor = {
      gid = 1000;
    };
    # security.sudo.extraRules = [
    #   {
    #     users = [ "taylor" ];
    #     commands = [
    #       {
    #         command = "ALL";
    #         options = [
    #           "SETENV"
    #           "NOPASSWD"
    #         ];
    #       }
    #     ];
    #   }
    # ];
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
        docker.enable = true;
        # traefik = {
        #   enable = true;
        #   domain = "t-vo.us";
        #   sans = [
        #     "*.t-vo.us"
        #     "nas-vm.t-vo.us"
        #   ];
        #   dashboardHost = "nas-vm.t-vo.us";
        #   # Routers and services are defined in their respective service modules:
        #   # - zerobyte.nix
        #   # - rustfs.nix
        # };

        samba = {
          enable = true;
          settings = {
            Media = {
              path = "/ook/Media";
              "read only" = "no";
              "guest ok" = "yes";
            };
            TimeMachineWork = {
              path = "/ook/TimeMachine/work";
              "read only" = "no";
              "fruit:aapl" = "yes";
              "fruit:time machine" = "yes";
              comment = "Work Macbook Time Machine";
            };
            Backup = {
              path = "/ook/Backup";
              "read only" = "no";
              "guest ok" = "no";
            };
            Documents = {
              path = "/ook/Documents";
              "read only" = "no";
              "guest ok" = "no";
            };
            paperless_inbox = {
              path = "/ook/k8s/paperless/consume";
              "read only" = "no";
              "guest ok" = "no";
            };
            Photos = {
              path = "/ook/Photos";
              "read only" = "no";
              "guest ok" = "no";
            };
          };
        };
        # * Note: doesn't work on a VM
        # smartd.enable = true;
        # smartctl-exporter.enable = true;
        # k3s disabled in favor of native services with traefik
        # k3s = {
        #   enable = true;
        #   extraFlags = [
        #     "--tls-san"
        #     "nas.mcbadass.local"
        #     "--flannel-backend=vxlan"
        #     "--disable-network-policy"
        #   ];
        # };
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
    #   efi.canTouchEfiVariables = true;
    #   systemd-boot.enable = true;
    # };
  };

  # # Group config
  # users.groups = {
  #   backup-rw = {
  #     gid = 65541;
  #     members = ["taylor"];
  #   };
  #   docs-rw = {
  #     gid = 65543;
  #     members = ["taylor"];
  #   };
  #   media-rw = {
  #     gid = 65539;
  #     members = ["taylor"];
  #   };
  # };

  # # ZFS config
  # boot.zfs = {
  #   devNodes = "/dev/disk/by-id";
  #   extraPools = [
  #     "ook"
  #   ];
  # };

  # # may fix issues with network service failing during a nixos-rebuild
  # systemd.services.NetworkManager-wait-online.enable = lib.mkForce false;
  # systemd.services.systemd-networkd-wait-online.enable = lib.mkForce false;

  # # This value determines the NixOS release from which the default
  # # settings for stateful data, like file locations and database versions
  # # on your system were taken. It's perfectly fine and recommended to leave
  # # this value at the release version of the first install of this system.
  # # Before changing this value read the documentation for this option
  # # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  # system.stateVersion = "24.05"; # Did you read the comment?
}
