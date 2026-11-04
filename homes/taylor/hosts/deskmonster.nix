{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    ./_workstation.nix
    # Imported here rather than in sharedModules: only deskmonster runs Plasma.
    inputs.plasma-manager.homeModules.plasma-manager
  ];

  modules = {
    editor.vscode = {
      enable = true;
      # The shared settings, with deskmonster's differences on top. recursiveUpdate
      # rather than //, so a nested group like "window" is merged, not replaced.
      userSettings =
        lib.recursiveUpdate
          # Drop the work Vertex AI config so Claude uses the personal login here.
          (removeAttrs (lib.importJSON ../config/editor/vscode/settings.json) [
            "claudeCode.environmentVariables"
          ])
          {
            # No Copilot sign-in or "Open in Agents" buttons in the title bar.
            "chat.commandCenter.enabled" = false;
            "chat.titleBar.openInAgentsWindow.enabled" = false;
          };
      # keyd's Cmd+C/V (hosts/deskmonster) send Ctrl/Shift+Insert, which the
      # editor treats as copy and paste but the terminal hands to the shell.
      keybindings = [
        {
          key = "ctrl+insert";
          command = "workbench.action.terminal.copySelection";
          when = "terminalFocus && terminalTextSelected";
        }
        {
          key = "shift+insert";
          command = "workbench.action.terminal.paste";
          when = "terminalFocus";
        }
      ];
    };
    terminal.ghostty = {
      enable = true;
      # keyd's Cmd+C/V (hosts/deskmonster) send these.
      extraSettings.keybind = [
        "ctrl+insert=copy_to_clipboard"
        "shift+insert=paste_from_clipboard"
      ];
    };
    # The 1Password desktop app serves the SSH keys (Settings > Developer >
    # Use the SSH agent).
    security.ssh.settings."*".IdentityAgent = "~/.1password/agent.sock";
  };
  # The same agent for tools that read SSH_AUTH_SOCK rather than ssh_config
  # (git signing, ssh-add).
  home.sessionVariables.SSH_AUTH_SOCK = "$HOME/.1password/agent.sock";

  # KRdp streams the whole 5120x1440 desktop by default, wider than many H.264
  # decoders accept (macOS FreeRDP shows a white screen); share the main
  # monitor only.
  xdg.configFile."systemd/user/app-org.kde.krdpserver.service.d/monitor.conf".text = ''
    [Service]
    ExecStart=
    ExecStart=${pkgs.kdePackages.krdp}/bin/krdpserver --monitor 0
  '';

  # CurseForge is a self-updating AppImage (programs.appimage, hosts/deskmonster)
  # kept in ~/Applications. Its login finishes by opening a cfauth:// link in
  # the app, which only works with an app menu entry claiming that scheme.
  xdg.desktopEntries.curseforge = {
    name = "CurseForge";
    exec = "${config.home.homeDirectory}/Applications/curseforge-latest-linux.AppImage %U";
    icon = "applications-games";
    categories = [ "Game" ];
    mimeType = [ "x-scheme-handler/cfauth" ];
  };

  programs.plasma = {
    enable = true;

    # Stays awake for RDP, SSH and downloads; only the monitors switch off.
    powerdevil.AC = {
      autoSuspend.action = "nothing";
      turnOffDisplay = {
        idleTimeout = 900;
        idleTimeoutWhenLocked = 60;
      };
      dimDisplay.enable = false;
    };

    # Windows minimise into the dock with KWin's version of the Mac genie effect.
    kwin.effects.minimization.animation = "magiclamp";

    # Screen-edge timing, which also drives the auto-hidden dock and the hot
    # corners; plasma-manager has no typed options for these.
    # ElectricBorderDelay: how long the mouse rests on the edge before it
    # fires (KDE default 150 ms). ElectricBorderCooldown: how soon the same
    # edge can fire again, e.g. re-showing the dock just after it hid (KDE
    # default 350 ms; KWin keeps it at least 50 ms above the delay).
    configFile.kwinrc.Windows = {
      ElectricBorderDelay = 0;
      ElectricBorderCooldown = 100;
    };

    # macOS's Mission Control keys, on top of KDE's defaults. These use the
    # physical Ctrl key, as on a Mac; keyd's Cmd layer (hosts/deskmonster)
    # covers the Cmd shortcuts.
    shortcuts.kwin = {
      "Overview" = [ "Meta+W" "Ctrl+Up" ]; # Mission Control
      "ExposeClass" = [ "Meta+F7" "Ctrl+Down" ]; # App Exposé
      "Switch One Desktop to the Left" = [ "Meta+Ctrl+Left" "Ctrl+Left" ];
      "Switch One Desktop to the Right" = [ "Meta+Ctrl+Right" "Ctrl+Right" ];
    };

    input.keyboard = {
      repeatDelay = 250; # ms before a held key starts repeating
      repeatRate = 40; # repeats per second
    };

    # Mac-style layout: menu bar on top, floating dock at the bottom, on every
    # screen. At the first login after this block changes, plasma-manager
    # deletes and rebuilds the whole panel layout, wiping panel edits made in
    # the GUI (pinned and unpinned icons included); change them here instead.
    # Plasma panels can't magnify icons on hover. Crystal Dock 2.16 can, but
    # crashes on Plasma 6.6 when it auto-hides (KWin rejects its screen-edge
    # request with a protocol error).
    panels = [
      # Dock
      {
        location = "bottom";
        screen = "all";
        alignment = "center";
        lengthMode = "fit";
        # Hidden until the mouse reaches the bottom edge, like the Mac dock's
        # "Automatically hide and show the Dock".
        hiding = "autohide";
        floating = true;
        height = 56;
        widgets = [
          {
            iconTasks.launchers = [
              "applications:org.kde.dolphin.desktop"
              "applications:firefox.desktop"
              "applications:brave-browser.desktop"
              "applications:com.mitchellh.ghostty.desktop"
              "applications:code.desktop"
              "applications:1password.desktop"
              "applications:steam.desktop"
              "applications:systemsettings.desktop"
            ];
          }
        ];
      }
      # Menu bar
      {
        location = "top";
        screen = "all";
        height = 28;
        floating = false;
        widgets = [
          {
            kickoff.icon = "nix-snowflake-white";
          }
          # Global menu: shows the focused app's menus here. KDE/Qt apps support
          # it; most GTK and Electron apps keep their own in-window menus.
          "org.kde.plasma.appmenu"
          "org.kde.plasma.panelspacer"
          "org.kde.plasma.systemtray"
          "org.kde.plasma.digitalclock"
        ];
      }
    ];
  };
}
