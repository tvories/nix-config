{ pkgs, config, ... }:
let ifTheyExist = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
in
{
  sops.secrets.tadmin-password = {
    sopsFile = ./secret.sops.yaml;
    neededForUsers = true;
  };
  users.mutableUsers = false;
  users.users.tadmin = {
    isNormalUser = true;
    shell = pkgs.fish;
    passwordFile = config.sops.secrets.tadmin-password.path;
    extraGroups = [
      "wheel"
    ] ++ ifTheyExist [
      "network"
      "samba-users"
    ];

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID2+7PUnROyy7dALYGxsQSN16hz4iblHXtFJ6dHCUIBW 1pw-linux-admin"
    ];

    packages = [ pkgs.home-manager ];
  };

  home-manager.users.tadmin = import ../../../../../home-manager/tadmin_${config.networking.hostName}.nix;
}
