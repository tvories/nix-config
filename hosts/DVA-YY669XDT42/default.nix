{
  pkgs,
  lib,
  hostname,
  ...
}:
{
  config = {
    # networking = {
    #   computerName = "Bernd's MacBook";
    #   hostName = hostname;
    #   localHostName = hostname;
    # };

    users.users.tvories = {
      name = "tvories";
      home = "/Users/tvories";
      shell = pkgs.fish;
      openssh.authorizedKeys.keys = lib.strings.splitString "\n" (builtins.readFile ../../homes/tvories/config/ssh/ssh.pub);
    };

    system.activationScripts.postActivation.text = ''
      # Must match what is in /etc/shells
      sudo chsh -s /run/current-system/sw/bin/fish tvories
    '';

    homebrew = {
      taps = [
      ];
      brews = [
      ];
      casks = [
        "discord"
        "google-chrome"
        "brave-browser"
        "obsidian"
        "orbstack"
        # "plex"
        # "tableplus"
        "transmit"
      ];
      masApps = {
        # "Adguard for Safari" = 1440147259;
        "Keka" = 470158793;
        "Passepartout" = 1433648537;
      };
    };
  };
}