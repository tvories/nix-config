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
    ./wireguard.nix
    ./restic-server.nix
    # ./auto-reboot.nix
    ./uptime-kuma.nix

    # Common imports
    # ../common/nixos
    # ../common/nixos/users/taylor
    # ../common/nixos/users/tadmin
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
    hardware = {
      raspberry-pi."4".apply-overlays-dtmerge.enable = true;
      raspberry-pi."4".bluetooth.enable = true;
      bluetooth = {
        enable = true;
        # powerOnBoot = true;
      };
      deviceTree = {
        enable = true;
        filter = "bcm2711-rpi-4*.dtb";
      };

      deviceTree = {
        overlays = [
          {
            name = "bluetooth-overlay";
            dtsText = ''
              /dts-v1/;
              /plugin/;

              / {
                  compatible = "brcm,bcm2711";

                  fragment@0 {
                      target = <&uart0_pins>;
                      __overlay__ {
                              brcm,pins = <30 31 32 33>;
                              brcm,pull = <2 0 0 2>;
                      };
                  };
              };
            '';
          }
        ];
      };
    };
    console.enable = true;
    nix.settings.trusted-users = [
      "root"
      "@wheel"
    ];
    networking = {
      firewall.enable = false;
      hostName = hostname;
      # hostId = "8023d2b9";
      domain = "mcbadass.local";
      dhcpcd.enable = true;
      # useNetworkd = true;
      nameservers = [
        "192.168.1.243"
        "1.1.1.1"
        "9.9.9.9"
        "192.168.1.240"
      ];
    };

    # Disk mount for usb drive
    fileSystems."/backup" = {
      device = "/dev/disk/by-id/usb-WDC_WD12_0EDAZ-11F3RA_000000000024-0:0-part1";
      fsType = "ext4";
      options = [
        "users"
        "nofail"
        "noatime"
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
          "backup-rw"
          "docker"
        ];
    };
    users.groups.taylor = {
      gid = 1000;
    };
    security.sudo.extraRules = [
      {
        users = [ "taylor" ];
        commands = [
          {
            command = "ALL";
            options = [
              "SETENV"
              "NOPASSWD"
            ];
          }
        ];
      }
    ];

    system.activationScripts.postActivation.text = ''
      # Must match what is in /etc/shells
      chsh -s /run/current-system/sw/bin/fish taylor
    '';

    # systemd.services.btattach = {
    #   before = [ "bluetooth.service" ];
    #   after = [ "dev-ttyAMA0.device" ];
    #   wantedBy = [ "multi-user.target" ];
    #   serviceConfig = {
    #     ExecStart = "${pkgs.bluez}/bin/btattach -B /dev/ttyAMA0 -P bcm -S 3000000";
    #   };
    # };

    environment.systemPackages = with pkgs; [
      # cryptsetup
      usbutils
      libraspberrypi
      raspberrypi-eeprom
    ];

    services.openssh.enable = true;
    modules = {
      services = {
        node-exporter.enable = true;
        smartctl-exporter.enable = true;
        msmtp.enable = true;
        docker.enable = true;
        traefik = {
          enable = true;
          domain = "t-vo.us";
          sans = [
            "*.t-vo.us"
            "tback.t-vo.us"
          ];
          dashboardHost = "tback.t-vo.us";
          # Routers and services are defined in their respective service modules:
          # - uptime-kuma.nix
        };
      };
      users = {
        additionalUsers = {
          # Backup user account
          tback = {
            uid = 1003;
            isNormalUser = true;
            hashedPasswordFile = config.sops.secrets.tback-password.path;
            extraGroups = [ "backup-rw" ];
            openssh.authorizedKeys.keys = [
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID6CloskNbqtcgAasuLxYwlAsVheXcZm1Jt37xpzmlda 1pw-backup-key"
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

    # sops.secrets.sda1-key = {
    #   sopsFile = ./secret.sops.yaml;
    # };
    sops.secrets.tback-password = {
      sopsFile = ./secret.sops.yaml;
      neededForUsers = true;
    };
    # services.autofs = {
    #   enable = true;
    #   autoMaster = ''
    #     /backup /etc/auto.luks --timeout=600
    #   '';
    #   debug = true;
    # };
    # environment.etc = {
    #   # Creates auto.luks file
    #   "auto.luks" = {
    #     text = ''
    #       #!/run/current-system/sw/bin/bash
    #       device=$1
    #       device_crypt=''${device}_autocrypt

    #       mountopts="-fstype=ext4,defaults,noatime,nodiratime"

    #       # map the LUKS device, if not already done
    #       /run/current-system/sw/bin/cryptsetup luksOpen /dev/''${device} ''${device_crypt} -d=/etc/.keys/''${device}.key 2>/dev/null

    #       echo $mountopts :/dev/mapper/''${device_crypt}
    #     '';
    #     mode = "0755";
    #   };
    #   ".keys/sda1.key" = {
    #     source = config.sops.secrets.sda1-key.path;
    #     mode = "0400";
    #   };
    # };

    # Restic server config
    sops.secrets.restic-server-htpasswd = {
      sopsFile = ./secret.sops.yaml;
      owner = "tback";
      path = "/home/tback/restic-server/.htpasswd";
    };
    sops.secrets.restic-public-cert = {
      sopsFile = ./secret.sops.yaml;
      owner = "tback";
      path = "/home/tback/restic-server/public.cert";
    };
    sops.secrets.restic-private-key = {
      sopsFile = ./secret.sops.yaml;
      owner = "tback";
      path = "/home/tback/restic-server/private.key";
    };
  };
}
