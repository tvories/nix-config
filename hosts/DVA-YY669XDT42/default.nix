{
  pkgs,
  lib,
  # hostname,
  ...
}:
{
  config = {
    users.users.tvories = {
      name = "tvories";
      home = "/Users/tvories";
      shell = pkgs.fish;
      openssh.authorizedKeys.keys = lib.strings.splitString "\n" (
        builtins.readFile ../../homes/taylor/config/ssh/ssh.pub
      );
    };
    ids.gids.nixbld = 350;

    system.activationScripts.postActivation.text = ''
      # Must match what is in /etc/shells
      sudo chsh -s /run/current-system/sw/bin/fish tvories
    '';

    #TODO: install homebrew somehow?

    homebrew = {
      taps = [ ];
      brews = [ "helm" ];
      casks = [
        # "discord"
        "google-chrome"
        "brave-browser"
        "obsidian"
        "orbstack"
        # "plex"
        # "tableplus"
        "transmit"
        "nextcloud"
        "apache-directory-studio"
        "vlc"
        "rustdesk"
        "headlamp"
        "middleclick"
        "plex"
        "utm"
      ];
      masApps = {
        # "Adguard for Safari" = 1440147259;
        # "Keka" = 470158793;
        "Passepartout" = 1433648537;
        "Wireguard" = 1451685025;
        "Amphetamine" = 937984704;
      };
    };
    programs.fish = {
      shellAliases = {
        tf = "terraform";
        # Vault
        platform-vault = "export VAULT_ADDR=https://platform-vault.davita.com; export VAULT_TOKEN=(vault login -token-only -method ldap)";
        platform-vault-sea = "export VAULT_ADDR=https://platform-vault-sea.davita.com; export VAULT_TOKEN=(vault login -token-only -method ldap)";
        gcp-vault = "export VAULT_ADDR=https://vault.gcp.davita.com; export VAULT_TOKEN=(vault login -token-only -method oidc)";

        adsearch = "ldapsearch -o ldif-wrap=no -H ldaps://10.9.92.49 -b dc=davita,dc=corp -D $USER@davita.corp -W";
      };
    };
    # Dock
    system = {
      defaults = {
        dock = {
          persistent-apps = [
            "/Applications/Firefox.app"
            "/Applications/iTerm.app"
            "/Applications/Microsoft Outlook.app"
            "/Applications/Microsoft Teams.app"
            "/Applications/Obsidian.app"
          ];
        };
      };
    };

    # Packages
    environment.systemPackages = with pkgs; [
      # Puppet stuff
      pdk
      puppet-lint
      ruby
      sqlite

      powershell
      openldap
      drawio
      terraform-ls
      jdk
      bruno
      d2
      vault
      lens
      discord
      jetbrains.goland
      windsurf
      glab
      claude-code

      (pkgs.bundlerApp {
        pname = "morpheus-cli";
        exes = [ "morpheus" ];
        gemdir = ./.;
      })
    ];

    nixpkgs.config = {
      ruby.package = pkgs.ruby;
      allowUnfree = true;
    };
  };
}
