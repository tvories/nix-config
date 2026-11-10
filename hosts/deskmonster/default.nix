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
    ./services.nix
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
    # Sunshine's ports (below) are opened here too, also home networks only.
    networking.firewall.extraCommands = ''
      iptables -A nixos-fw -p tcp -s 192.168.0.0/16 --dport 3389 -j nixos-fw-accept
      iptables -A nixos-fw -p tcp -s 192.168.0.0/16 -m multiport --dports 47984,47989,48010 -j nixos-fw-accept
      iptables -A nixos-fw -p udp -s 192.168.0.0/16 -m multiport --dports 47998:48000,48002,48010 -j nixos-fw-accept
    '';

    # Game streaming to Moonlight (the Shield TV). Starts with the auto-login
    # session, so the stream opens on the lock screen until it's unlocked.
    services.sunshine = {
      enable = true;
      # Wayland capture reads the screen through KMS, which needs CAP_SYS_ADMIN.
      capSysAdmin = true;
      # nixpkgs builds Sunshine without CUDA, which leaves it encoding through
      # Vulkan; NVENC is better tuned (colour, quality per bit). Not in the
      # binary cache, so it compiles locally on the first switch.
      package = pkgs.sunshine.override {
        cudaSupport = true;
        inherit (pkgs) cudaPackages;
      };
      # Opened above for the home networks only, like RDP. The web UI (47990)
      # stays local: pair and configure at https://localhost:47990.
      openFirewall = false;
      # Replaces the default app list (so Desktop is listed again here), and
      # makes the web UI's app editor read-only.
      applications.apps = [
        {
          name = "Desktop";
          image-path = "desktop.png";
        }
        {
          name = "World of Warcraft";
          # Detached: Lutris hands off to Battle.net and exits, which would
          # otherwise end the stream at launch. Battle.net opens WoW Forever
          # (product code wowf) via --exec="launch wowf" in its Lutris game
          # options.
          detached = [ "env LUTRIS_SKIP_INIT=1 ${pkgs.lutris}/bin/lutris lutris:rungameid/1" ];
        }
      ];
    };

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
      # The Ducky only takes per-key colours from OpenRGB (Direct mode), so
      # moving effects like a rainbow wave have to be drawn by the Effects
      # plugin, which this build includes.
      package = pkgs.openrgb-with-all-plugins;
    };

    programs.firefox = {
      enable = true;
      preferences = {
        "media.ffmpeg.vaapi.enabled" = true;
        "media.hardware-video-decoding.force-enabled" = true;
        # Middle-click scrolling, on by default everywhere except Linux.
        "general.autoScroll" = true;
      };
    };
    programs._1password.enable = true;
    programs._1password-gui = {
      enable = true;
      # Lets the CLI and browser extension unlock through the desktop app.
      polkitPolicyOwners = [ "taylor" ];
    };

    # Managed policies for ungoogled-chromium (in systemPackages below), written
    # to /etc/chromium/policies/managed. Turns off the built-in password
    # manager in favour of 1Password. Check with chrome://policy.
    programs.chromium = {
      enable = true;
      extraOpts = {
        PasswordManagerEnabled = false;
        RestoreOnStartup = 1;
      };
    };

    # GeForce Now's Linux app is only distributed as a Flatpak.
    services.flatpak.enable = true;

    modules.services.docker.enable = true;

    # Scraped by the cluster's Prometheus (k8s-gitops kube-prometheus-stack):
    # node-exporter by scrapeconfigs/deskmonster.yaml, the GPU by the
    # nvidia_gpu_exporter job in helm-release.yaml, which Windows' exporter
    # also answers on the same port.
    modules.services.node-exporter = {
      enable = true;
      openFirewall = true;
    };
    modules.services.nvidia-gpu-exporter = {
      enable = true;
      openFirewall = true;
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
        "docker"
        "gamemode"
        # Claude Desktop's Cowork runs tasks in a KVM VM and needs
        # /dev/vhost-vsock, which only this group can open.
        "kvm"
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
      # Chromium-based browser for sites that need one. ungoogled-chromium
      # rather than Brave, which nixpkgs dropped (2026-11) for unpatched
      # security issues. Chromium leaves middle-click scrolling off on Linux;
      # this Blink feature turns it on.
      (ungoogled-chromium.override {
        commandLineArgs = "--enable-blink-features=MiddleClickAutoscroll";
      })
      usbutils
      pciutils
      # Picks the OS for the next boot (`efibootmgr --bootnext`), for
      # switching to Windows remotely.
      efibootmgr
      rebootWindows
      rebootNix
      claude-code
      signal-desktop
      (callPackage ../../pkgs/claude-desktop.nix { })
      # At /run/current-system/sw/bin/rg, where the shared VS Code settings
      # point Todo Tree (as on the Macs).
      ripgrep
      powershell
      sops
      python3
      # Current LTS line. Also provides the npx that the agentmemory MCP
      # server's client runs from (~/.claude.json).
      nodejs_26
      gnumake
      gcc
      uv
      # KDE's macOS look: themes, icons and cursors to apply in System Settings.
      whitesur-kde
      whitesur-icon-theme
      whitesur-cursors
    ];

    # The Macs' fonts (hosts/_modules/darwin/fonts.nix), so Ghostty, VS Code
    # and the shell prompt's icons look the same here.
    fonts.packages = with pkgs; [
      font-awesome
      monaspace
      atkinson-hyperlegible
      nerd-fonts.jetbrains-mono
      nerd-fonts.droid-sans-mono
      nerd-fonts.fira-code
      nerd-fonts.bitstream-vera-sans-mono
      # Ghostty asks for "Bitstream Vera Sans Mono"; the Nerd Font build above
      # is named "BitstromWera", so it needs the original too. Ghostty draws
      # the Nerd Font icons itself.
      ttf_bitstream_vera
    ];

    services.openssh = {
      enable = true;
      settings.PasswordAuthentication = false;
    };
  };
}
