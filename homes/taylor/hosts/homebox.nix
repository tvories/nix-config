{
  lib,
  config,
  pkgs,
  ...
}:
{
  modules = {
    shell = {
      atuin = {
        enable = true;
        package = pkgs.unstable.atuin;
        flags = [ "--disable-up-arrow" ];
        settings = {
          sync_address = "https://atuin.t-vo.us";
          # key_path = config.sops.secrets.atuin_work_key.path;
          auto_sync = true;
          sync_frequency = "1m";
          search_mode = "fuzzy";
          sync = {
            records = true;
          };
        };
      };
      git = {
        enable = true;
        username = "Taylor Vories";
        email = "taylor@tmtech.me";
      };
    };
  };
}
