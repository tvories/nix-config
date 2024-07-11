{
  pkgs,
  lib,
  ...
}:
{
  config = {
    homebrew = {
      taps = [];
      brews = [];
      casks = [
        "google-chrome"
        "obsidian"
        "discord"
      ];
      masApps = [];
    };
  };
}