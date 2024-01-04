{ pkgs, config, ... }:
let ifTheyExist = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
in
{
  # sops.secrets.taylor-password = {
  #   sopsFile = ./secret.sops.yaml;
  #   neededForUsers = true;
  # };
  # users.mutableUsers = false;
  users.users.taylor = {
    isNormalUser = true;
    shell = pkgs.fish;
    # passwordFile = config.sops.secrets.taylor-password.path;
    initialHashedPassword = "$y$j9T$hbT0Eeox2XSgwlFIaxEmh.$PBtYZ0w1M9.rGbKBYz8MEo.59Sv3gFwJdxS4BI7G7S5";
    extraGroups = [
      "wheel"
    ] ++ ifTheyExist [
      "network"
      "samba-users"
    ];

    # modules.users.taylor.sops = {
    #   defaultSopsFile = ./secret.sops.yaml;
    #   secrets = {
    #     atuin_key = {
    #       path = "${config.home-manager.users.taylor.xdg.configHome}/atuin/key";
    #     };
    #   };
    # };

    # modules.users.taylor.shell.atuin = {
    #   enable = true;
    #   package = pkgs-unstable.atuin;
    #   sync_address = "https://atuin.t-vo.us";
    #   config = {
    #     key_path = config.home-manager.users.taylor.sops.secrets.atuin_key.path;
    #   };
    # };

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHthY1nXKAUHoco25JcN5qZ2sNs34gKCmXH4jslR5/tN 1pw-taylor"
    ];

    packages = [ pkgs.home-manager ];
  };

  home-manager.users.taylor = import ../../../../../home-manager/taylor_${config.networking.hostName}.nix;
}
