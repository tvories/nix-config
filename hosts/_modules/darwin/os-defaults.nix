_: {
  security.pam.services.sudo_local.touchIdAuth = true;

  environment = {
    pathsToLink = [ "/Applications" ];
  };

  system = {
    defaults = {
      finder = {
        # Show status bar
        ShowStatusBar = true;
        # Default Finder window set to list view
        FXPreferredViewStyle = "Nlsv";
        # Show path bar
        ShowPathbar = true;
        # Show all extensions
        AppleShowAllExtensions = true;
        # Show icons on desktop
        CreateDesktop = false;
        # Disable warning when changing file extension
        FXEnableExtensionChangeWarning = false;
        _FXShowPosixPathInTitle = true;
      };
      NSGlobalDomain = {
        # Whether to automatically switch between light and dark mode.
        AppleInterfaceStyleSwitchesAutomatically = false;
        # Set Dark Mode
        AppleInterfaceStyle = "Dark";
        # Whether to show all file extensions in Finder
        AppleShowAllExtensions = true;
        # Whether to enable automatic capitalization.  The default is true
        NSAutomaticCapitalizationEnabled = false;
        # Whether to enable smart dash substitution.  The default is true
        NSAutomaticDashSubstitutionEnabled = false;
        # Whether to enable smart period substitution.  The default is true
        NSAutomaticPeriodSubstitutionEnabled = false;
        # Whether to enable smart quote substitution.  The default is true
        NSAutomaticQuoteSubstitutionEnabled = false;
        # Whether to enable automatic spelling correction.  The default is true
        NSAutomaticSpellingCorrectionEnabled = false;
        # Sets the size of the finder sidebar icons: 1 (small), 2 (medium) or 3 (large). The default is 3.
        NSTableViewDefaultSizeMode = 1;
        # Configures the trackpad tap behavior.  Mode 1 enables tap to click.
        "com.apple.mouse.tapBehavior" = 1;
        # Whether to enable trackpad secondary click.
        "com.apple.trackpad.enableSecondaryClick" = true;
        # Whether to autohide the menu bar.
        _HIHideMenuBar = false;

        # Keyboard
        # Configures the keyboard control behavior.  Mode 3 enables full keyboard control
        AppleKeyboardUIMode = 3;
        # If you press and hold certain keyboard keys when in a text area, the key’s character begins to repeat. For example, the Delete key continues to remove text for as long as you hold it down.
        InitialKeyRepeat = 14;
        # This sets how fast it repeats once it starts.
        KeyRepeat = 2;
      };

      dock = {
        # Show appswitcher on all displays
        appswitcher-all-displays = false;
        # Automatically show and hide the dock
        autohide = true;
        # Position of the dock on screen.
        # orientation = "left";
        # Show recent applications in the dock.
        show-recents = false;
        # Magnify icon on hover. The default is false.
        magnification = true;
        # Enable spring loading for all Dock items. The default is false.
        enable-spring-load-actions-on-all-items = true;
        # Magnified icon size on hover. The default is 16.
        largesize = 120;
      };
    };

    keyboard = {
      enableKeyMapping = true;
    };
  };

}
