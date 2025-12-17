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
    ./disk-config.nix
    ./hardware-configuration.nix
    # ./3d-printing.nix
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

    console.enable = true;
    nix.settings.trusted-users = [
      "root"
      "@wheel"
    ];
    networking = {
      firewall.enable = false;
      hostName = hostname;
      domain = "mcbadass.local";
      dhcpcd.enable = true;
      # wireless.enable  = true;
      networkmanager.enable = true;
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
        "networkmanager"
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

    environment.systemPackages = with pkgs; [
      # cryptsetup
      usbutils
      # libraspberrypi
      # raspberrypi-eeprom
    ];

    services.openssh.enable = true;
    modules = {
      services = {
        node-exporter.enable = true;
        msmtp.enable = true;
        docker.enable = true;
        smartd.enable = true;
        smartctl-exporter.enable = true;
      };
    };
    boot.kernelParams = [
      "i915.enable_guc=2"
    ];

    hardware.graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver
        intel-compute-runtime
      ];
    };
  };
}
