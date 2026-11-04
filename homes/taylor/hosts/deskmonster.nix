{
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

  # KRdp streams the whole 5120x1440 desktop by default, wider than many H.264
  # decoders accept (macOS FreeRDP shows a white screen); share the main
  # monitor only.
  xdg.configFile."systemd/user/app-org.kde.krdpserver.service.d/monitor.conf".text = ''
    [Service]
    ExecStart=
    ExecStart=${pkgs.kdePackages.krdp}/bin/krdpserver --monitor 0
  '';

  # The dock. Plasma's own panels can't magnify icons on hover; Crystal Dock
  # can, and auto-hides through KWin's screen edges (so ElectricBorderDelay
  # below sets how fast it appears). Its launchers, zoom and hiding are set in
  # its own right-click menu and kept in ~/.config/crystal-dock.
  home.packages = [ pkgs.crystal-dock ];
  xdg.configFile."autostart/crystal-dock.desktop".source =
    "${pkgs.crystal-dock}/share/applications/crystal-dock.desktop";

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

    # How long the mouse has to rest on a screen edge before it fires (KDE's
    # default is 150 ms). Covers the auto-hidden dock and the hot corners
    # alike; plasma-manager has no typed option for it.
    configFile.kwinrc.Windows.ElectricBorderDelay = 50;

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

    # Mac-style menu bar on top of every screen; the dock is Crystal Dock
    # (below). At the first login after this block changes, plasma-manager
    # deletes and rebuilds the whole panel layout, wiping panel edits made in
    # the GUI; change them here instead.
    panels = [
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
