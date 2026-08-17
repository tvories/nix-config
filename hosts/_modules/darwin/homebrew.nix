_: {
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = false; # Don't update during rebuild
      cleanup = "none"; # TODO: revert to "zap" once nix-darwin fixes --force-cleanup for Homebrew 5.x
      upgrade = true;
    };
    global = {
      brewfile = true; # Run brew bundle from anywhere
    };
    taps = [ ];
    brews = [ ];
    casks = [
      "1password"
      "gifox"
      "iterm2"
      "jordanbaird-ice"
      "karabiner-elements"
      "keyboard-maestro"
      "notunes"
      "raycast"
      "shottr"
      "firefox"
      "scroll-reverser"
    ];
    masApps = {
      # "Caffeinated" = 1362171212;
      # "Jolt of Caffeine" = 1437130425;
    };
  };
}
