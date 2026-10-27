{
  pkgs,
  config,
  ...
}: let
  ageKeyFile = "${config.xdg.configHome}/age/keys.txt";
in {
  config = {
    home.packages = [
      pkgs.sops
      pkgs.age
    ];

    sops = {
      defaultSopsFile = ./secrets.sops.yaml;
      age.keyFile = ageKeyFile;
      age.generateKey = true;

      secrets = {
        # atuin_key / atuin_password: declared by modules.shell.atuin.autoLogin
        atuin_work_key = {};
      };
    };

    home.sessionVariables = {
      SOPS_AGE_KEY_FILE = ageKeyFile;
    };
  };
}
