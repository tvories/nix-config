{
  inputs,
  outputs,
  config,
  ...
}:
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.sops-nix.nixosModules.sops
    ./locale.nix
    ./nix.nix
    ./packages.nix
    # ./openssh.nix
    # ./systemd-initrd.nix
    # ./secrets.nix
  ] ++ (builtins.attrValues { });

  home-manager.extraSpecialArgs = {
    inherit inputs outputs;
  };

  nixpkgs = {
    # Add overlays here
    overlays = [ outputs.overlays.unstable-packages ];
    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages
      allowUnfree = true;
    };
  };

  # Shared sops location
  sops.age.keyFile = "/var/lib/sops-nix/key.txt";

  # Increase open file limit for sudoers
  security.pam.loginLimits = [
    {
      domain = "@wheel";
      item = "nofile";
      type = "soft";
      value = "524288";
    }
    {
      domain = "@wheel";
      item = "nofile";
      type = "hard";
      value = "1048576";
    }
  ];

  # sops.secrets.msmtp = {
  #   sopsFile = ./secret.sops.yaml;
  # }

  # Email settings
  programs.msmtp = {
    enable = true;
    accounts.default = {
      host = "smtp-relay.mcbadass.local";
      from = "${config.networking.hostName}@t-vo.us";
    };
    defaults = {
      aliases = "/etc/aliases";
    };
  };

  environment.etc = {
    "aliases" = {
      text = ''
        root: ${config.networking.hostName}@t-vo.us
      '';
      mode = "0644";
    };
  };
}
