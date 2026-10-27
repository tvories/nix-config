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
  # Compulab fitlet2 (Apollo Lake): kid's PC for games and learning to type.
  imports = [
    ./disk-config.nix
    ./hardware-configuration.nix
    ./pegasus.nix
    # Temporary: Echo Dot 2nd gen flashing tools. Remove once it's flashed.
    ./amonet.nix
  ];

  config = {
    # Kept here rather than in hardware-configuration.nix so regenerating that
    # file on the real hardware can't drop the bootloader.
    boot.loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 10;
      };
      efi.canTouchEfiVariables = true;
    };

    hardware.enableRedistributableFirmware = true;
    hardware.graphics = {
      enable = true;
      extraPackages = [ pkgs.intel-media-driver ];
    };

    networking = {
      hostName = hostname;
      domain = "mcbadass.local";
      # Desktop machine that may move between wired and wifi.
      networkmanager.enable = true;
    };

    time.timeZone = "America/Denver";

    services.xserver = {
      enable = true;
      desktopManager.xfce = {
        enable = true;
        # No lock screen: the kid account logs in automatically and has no
        # password to unlock with.
        enableScreensaver = false;
      };
    };
    services.displayManager.autoLogin = {
      enable = true;
      user = "kid";
    };

    services.pipewire = {
      enable = true;
      pulse.enable = true;
    };

    modules.users.additionalUsers.kid = {
      isNormalUser = true;
      description = "Kid";
      # Not in wheel: no sudo. Set a password with `sudo passwd kid` if the
      # account should ever be locked.
      extraGroups = [
        "audio"
        "video"
        "networkmanager"
      ];
      # Games and learning apps are installed from the launcher's list in
      # pegasus.nix.
      packages = [ pkgs.firefox ];
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
        "networkmanager"
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
      usbutils
      pciutils
    ];

    services.openssh.enable = true;
  };
}
