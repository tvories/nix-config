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
    # <nixos-hardware/raspberry-pi/4>
    ./hardware-configuration.nix
    # ./wireguard.nix
    # ./restic-server.nix
    # ./auto-reboot.nix

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
    # Pi settings
    # hardware = {
    #   raspberry-pi."4".apply-overlays-dtmerge.enable = true;
    #   deviceTree = {
    #     enable = true;
    #     filter = "*rpi-4-*.dtb";
    #   };
    # };
    # console.enable = false;
    # nix.settings.trusted-users = [
    #   "root"
    #   "@wheel"
    # ];
    networking = {
      firewall.enable = false;
      hostName = hostname;
      # hostId = "8023d2b9";
      domain = "mcbadass.local";
      # dhcpcd.enable = true;
      # useNetworkd = true;
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

    # system.activationScripts.postActivation.text = ''
    #   # Must match what is in /etc/shells
    #   chsh -s /run/current-system/sw/bin/fish taylor
    # '';

    # environment.systemPackages = with pkgs; [
    #   cryptsetup
    #   usbutils
    #   libraspberrypi
    #   raspberrypi-eeprom
    # ];

    services.openssh.enable = true;
    # modules = {
    #   services = {
    #     nfs.enable = true;
    #     node-exporter.enable = true;
    #     smartctl-exporter.enable = true;
    #     # openssh.enable = true;
    #     # msmtp.enable = true;

    #     restic-server = {
    #       enable = true;
    #       restic-path = "/backup/sda1/restic";
    #       htpasswd-file = "/home/tback/restic-server/.htpasswd";
    #       public-cert-file = "/home/tback/restic-server/public.cert";
    #       private-key-file = "/home/tback/restic-server/private.key";
    #       working-directory = "/home/tback/restic-server";
    #       group = "65541"; # backup-rw
    #       user = "tback";
    #     };
    #   };
    #   users = {
    #     additionalUsers = {
    #       # Backup user account
    #       tback = {
    #         uid = 1003;
    #         isNormalUser = true;
    #         hashedPasswordFile = config.sops.secrets.tback-password.path;
    #         extraGroups = [ "backup-rw" ];
    #         openssh.authorizedKeys.keys = [
    #           "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID6CloskNbqtcgAasuLxYwlAsVheXcZm1Jt37xpzmlda 1pw-backup-key"
    #         ];
    #       };
    #     };
    #     groups = {
    #       svc_scanner = { };
    #       backup-rw = {
    #         gid = 65541;
    #         members = [ "taylor" ];
    #       };
    #       admins = {
    #         gid = 991;
    #         members = [ "taylor" ];
    #       };
    #       docs-rw = {
    #         gid = 65543;
    #         members = [ "taylor" ];
    #       };
    #       media-rw = {
    #         gid = 65539;
    #         members = [ "taylor" ];
    #       };
    #     };
    #   };
    # };

    # sops.secrets.sda1-key = {
    #   sopsFile = ./secret.sops.yaml;
    # };
    # sops.secrets.tback-password = {
    #   sopsFile = ./secret.sops.yaml;
    #   neededForUsers = true;
    # };
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

    # # Restic server config
    # sops.secrets.restic-server-htpasswd = {
    #   sopsFile = ./secret.sops.yaml;
    #   owner = "tback";
    #   path = "/home/tback/restic-server/.htpasswd";
    # };
    # sops.secrets.restic-public-cert = {
    #   sopsFile = ./secret.sops.yaml;
    #   owner = "tback";
    #   path = "/home/tback/restic-server/public.cert";
    # };
    # sops.secrets.restic-private-key = {
    #   sopsFile = ./secret.sops.yaml;
    #   owner = "tback";
    #   path = "/home/tback/restic-server/private.key";
    # };
  };

  # services.prometheus.exporters = {
  #   node = {
  #     enable = true;
  #     enabledCollectors = [
  #       "diskstats"
  #       "filesystem"
  #       "loadavg"
  #       "meminfo"
  #       "netdev"
  #       "stat"
  #       "time"
  #       "uname"
  #       "systemd"
  #     ];
  #   };
  #   smartctl = {
  #     enable = true;
  #   };
  # };

  # may fix issues with network service failing during a nixos-rebuild
  # systemd.services.NetworkManager-wait-online.enable = lib.mkForce false;
  # systemd.services.systemd-networkd-wait-online.enable = lib.mkForce false;

  # system.stateVersion = "24.05";
  # nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
