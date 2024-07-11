{
  pkgs,
  config,
  ...
}: let
  ageKeyFile = "${config.users.users.taylor.home}/.config/age/keys.txt";
in {
  config = {
    environment.systemPackages = [
      pkgs.sops
      pkgs.age
    ];

    sops = {
      age.keyFile = ageKeyFile;
      age.generateKey = true;
    };
  };
}