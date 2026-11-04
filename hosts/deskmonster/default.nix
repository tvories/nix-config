{
  pkgs,
  lib,
  config,
  hostname,
  ...
}:
let
  ifGroupsExist = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;

  # Locks only the first session of each boot (the auto-login), not later
  # logins made at the keyboard.
  lockOncePerBoot = pkgs.writeShellApplication {
    name = "lock-once-per-boot";
    runtimeInputs = with pkgs; [
      coreutils
      systemd
    ];
    text = ''
      boot=$(cat /proc/sys/kernel/random/boot_id)
      stamp=''${XDG_CACHE_HOME:-$HOME/.cache}/locked-boot-id
      if [ "$(cat "$stamp" 2>/dev/null)" != "$boot" ]; then
        mkdir -p "$(dirname "$stamp")"
        echo "$boot" > "$stamp"
        # Give the screen locker a moment to come up with the session.
        sleep 3
        loginctl lock-session
      fi
    '';
  };

  # One-shot UEFI BootNext, then reboot. Entries are found by what they boot,
  # not their number: firmware renumbers them, and NixOS's shows up as a
  # generic "UEFI OS" since it was installed from WSL.
  mkRebootTo =
    name: match:
    pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = with pkgs; [
        efibootmgr
        gnugrep
        util-linux
        systemd
      ];
      text = ''
        entry=$(efibootmgr | grep -i -m1 "${match}" | grep -o '^Boot[0-9A-F]\{4\}' | cut -c5-) || true
        if [ -z "$entry" ]; then
          echo "${name}: no UEFI boot entry matches ${match}" >&2
          efibootmgr >&2
          exit 1
        fi
        sudo efibootmgr --quiet --bootnext "$entry"
        systemctl reboot
      '';
    };
  rebootWindows = mkRebootTo "reboot-windows" "BOOTMGFW.EFI";
  # Matches this system's ESP, so it keeps working if the entry is renamed.
  rebootNix = mkRebootTo "reboot-nix" "$(findmnt -no PARTUUID /boot)";
in
{
  # Desktop PC (Ryzen 5 5600X, RTX 3080), on trial alongside Windows: NixOS on
  # the Intel 660p NVMe, Windows untouched on the 980 PRO.
  imports = [
    ./disk-config.nix
    ./hardware-configuration.nix
    ./gaming.nix
  ];

  config = {
    boot.loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 10;
      };
      efi.canTouchEfiVariables = true;
    };
    # Windows keeps the hardware clock in local time; matching it stops the
    # clock jumping by the UTC offset after every switch between the two.
    time.hardwareClockInLocalTime = true;
    time.timeZone = "America/Denver";

    # A remote-access box that must not sleep: this also catches the power
    # menu's Sleep, the login screen and anything else that asks systemd.
    systemd.targets = lib.genAttrs [ "sleep" "suspend" "hibernate" "hybrid-sleep" ] (_: {
      enable = false;
    });

    hardware.enableRedistributableFirmware = true;
    zramSwap.enable = true;

    networking = {
      hostName = hostname;
      domain = "mcbadass.local";
      networkmanager.enable = true;
    };

    # NVIDIA's open kernel module (Turing and newer) is the recommended driver
    # for the RTX 3080. Wayland has worked well with it since the 555 driver
    # added explicit sync, which fixed the flicker and frame pacing problems.
    services.xserver.videoDrivers = [ "nvidia" ];
    hardware.nvidia = {
      open = true;
      modesetting.enable = true;
      # Saves VRAM across suspend, so apps don't come back corrupted.
      powerManagement.enable = true;
      # The newest driver branch reaches unstable well before the release
      # branch; build unstable's driver against this system's kernel.
      package =
        (pkgs.unstable.linuxKernel.packagesFor config.boot.kernelPackages.kernel).nvidiaPackages.latest;
    };
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
      # VA-API on top of NVDEC, for hardware video decoding in browsers.
      extraPackages = [ pkgs.nvidia-vaapi-driver ];
    };
    environment.sessionVariables = {
      LIBVA_DRIVER_NAME = "nvidia";
      NVD_BACKEND = "direct";
      # Firefox's media sandbox blocks the direct backend.
      MOZ_DISABLE_RDD_SANDBOX = "1";
    };

    services.desktopManager.plasma6.enable = true;
    services.displayManager.sddm = {
      enable = true;
      wayland.enable = true;
    };
    # KRdp (below) can only share a running session, so log in at boot and
    # lock at once: RDP then shows the lock screen, as Windows' login would.
    services.displayManager.autoLogin = {
      enable = true;
      user = "taylor";
    };
    services.displayManager.defaultSession = "plasma";
    environment.etc."xdg/autostart/lock-after-autologin.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=Lock after auto-login
      Exec=${lib.getExe lockOncePerBoot}
      X-GNOME-Autostart-enabled=true
    '';
    # Remote desktop: Plasma's KRdp shares the logged-in session over RDP. Turn
    # it on and set its login under System Settings > Remote Desktop. Only
    # reachable from the home networks.
    networking.firewall.extraCommands = ''
      iptables -A nixos-fw -p tcp -s 192.168.0.0/16 --dport 3389 -j nixos-fw-accept
    '';

    # Mac muscle memory on a PC keyboard: left Alt sits where Cmd does and
    # acts like it, and Win becomes Alt (Option). The Cmd layer is Ctrl for
    # any key not listed, so Cmd+T/W/S/Z/Q go to the usual Ctrl shortcuts,
    # while the physical Ctrl key stays Ctrl (Ctrl+C still interrupts).
    services.keyd = {
      enable = true;
      keyboards.default = {
        ids = [ "*" ];
        settings = {
          main = {
            leftalt = "layer(meta_mac)";
            leftmeta = "leftalt";
          };
          "meta_mac:C" = {
            # Ctrl/Shift+Insert copy and paste in terminals as well as GUI
            # apps, where Ctrl+C/V would be interrupt and literal-next.
            c = "C-insert";
            v = "S-insert";
            x = "S-delete";
            # Hold Cmd and tap Tab to cycle windows, as on a Mac.
            tab = "swapm(app_switch_state, A-tab)";
            # Spotlight: KRunner.
            space = "A-space";
            q = "A-f4";
            # Sent as KWin's own shortcuts rather than Ctrl+`/Ctrl+M, which
            # apps use (VS Code's terminal; Enter in terminals).
            grave = "A-grave"; # next window of this app
            m = "M-pagedown"; # minimize
            left = "home";
            right = "end";
            up = "C-home";
            down = "C-end";
          };
          "app_switch_state:A" = { };
        };
      };
    };

    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
    hardware.bluetooth.enable = true;

    services.printing.enable = true;
    # Finds network printers and scanners (IPP Everywhere, eSCL).
    services.avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };
    hardware.sane.enable = true;

    # Logitech receivers (Solaar) and gaming mice (Piper).
    hardware.logitech.wireless = {
      enable = true;
      enableGraphical = true;
    };
    services.ratbagd.enable = true;
    services.hardware.openrgb = {
      enable = true;
      motherboard = "amd";
    };

    programs.firefox = {
      enable = true;
      preferences = {
        "media.ffmpeg.vaapi.enabled" = true;
        "media.hardware-video-decoding.force-enabled" = true;
      };
    };
    programs._1password.enable = true;
    programs._1password-gui = {
      enable = true;
      # Lets the CLI and browser extension unlock through the desktop app.
      polkitPolicyOwners = [ "taylor" ];
    };

    # Brave (in systemPackages below) reads managed policies from here. Switches off its crypto, VPN, AI
    # and news extras, and its password manager in favour of 1Password.
    # Check with brave://policy.
    environment.etc."brave/policies/managed/privacy.json".text = builtins.toJSON {
      BraveRewardsDisabled = true;
      BraveWalletDisabled = true;
      BraveVPNDisabled = true;
      BraveAIChatEnabled = false;
      BraveNewsDisabled = true;
      BraveTalkDisabled = true;
      PasswordManagerEnabled = false;
    };

    # GeForce Now's Linux app is only distributed as a Flatpak.
    services.flatpak.enable = true;

    modules.services.docker.enable = true;

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
        "docker"
        "gamemode"
        "scanner"
        "lp"
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

    nix.settings.trusted-users = [
      "root"
      "taylor"
    ];
    programs.nh.flake = "/home/taylor/gits/nix-config";
    # Lets mise's precompiled runtimes and other prebuilt binaries run.
    programs.nix-ld.enable = true;

    environment.systemPackages = with pkgs; [
      # Chromium-based browser for sites that need one; Brave for its built-in
      # tracker blocking and fingerprint randomisation.
      brave
      usbutils
      pciutils
      # Picks the OS for the next boot (`efibootmgr --bootnext`), for
      # switching to Windows remotely.
      efibootmgr
      rebootWindows
      rebootNix
      claude-code
      powershell
      sops
      python3
      gnumake
      gcc
      uv
      # KDE's macOS look: themes, icons and cursors to apply in System Settings.
      whitesur-kde
      whitesur-icon-theme
      whitesur-cursors
    ];

    services.openssh = {
      enable = true;
      settings.PasswordAuthentication = false;
    };
  };
}
