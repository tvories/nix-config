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
    ./disk-config.nix
    ./hardware-configuration.nix
  ];

  config = {
    nix.settings.trusted-users = [
      "root"
      "@wheel"
    ];

    networking = {
      firewall.enable = true;
      hostName = hostname;
      # domain = "mcbadass.local";
      networkmanager.enable = true;
      # nameservers = [
      #   "192.168.1.243"
      #   "1.1.1.1"
      #   "9.9.9.9"
      # ];
    };

    # Rosetta 2 support for running x86_64 binaries on aarch64-linux.
    # Requires UTM to be configured with a VirtioFS share named "rosetta"
    # pointing to /Library/Apple/usr/libexec/oah/libRosettaRuntime on macOS.
    # In UTM: VM Settings -> Sharing -> enable "Use Apple Virtualization" and
    # "Enable Rosetta" (or manually add a VirtioFS share tagged "rosetta").
    virtualisation.rosetta = {
      enable = true;
    };

    # GNOME desktop environment
    services = {
      xserver.enable = true;
      displayManager.gdm = {
        enable = true;
        # Disable Wayland so XRDP sessions work correctly via X11
        # wayland = false;
      };
      desktopManager.gnome.enable = true;

      # XRDP for remote desktop access (port 3389)
      xrdp = {
        enable = true;
        defaultWindowManager = "${pkgs.writeShellScript "xrdp-gnome-session" ''
          . /etc/profile
          export XDG_SESSION_TYPE=x11
          export XDG_CURRENT_DESKTOP=GNOME
          export LIBGL_ALWAYS_SOFTWARE=1
          exec ${pkgs.dbus}/bin/dbus-run-session -- ${pkgs.gnome-session}/bin/gnome-session
        ''}";
        openFirewall = true;
      };
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
      usbutils
      dnsutils
      gnome-tweaks
    ];

    modules = {
      services = {
        openssh.enable = true;
        node-exporter.enable = true;
      };
    };
  };
}
