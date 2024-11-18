{
  lib,
  config,
  pkgs,
  ...
}:
{
  modules = {
    deployment.nix.enable = true;
    development.enable = true;
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
    kubernetes.enable = true;
    security = {
      ssh = {
        enable = true;
        matchBlocks = {
          "tback.mcbadass.local" = {
            port = 22;
            user = "taylor";
            identityFile = "/home/taylor/nixos-taylor";
            checkHostIP = false;
          };
          "nas-vm.mcbadass.local" = {
            port = 22;
            user = "taylor";
            identityFile = "/home/taylor/nixos-taylor";
            checkHostIP = false;
          };
          "192.168.1.97" = {
            port = 22;
            user = "root";
            identityFile = "/home/taylor/nixos-root";
            checkHostIP = false;
          };
          "nas3.mcbadass.local" = {
            port = 22;
            user = "taylor";
            identityFile = "/home/taylor/nixos-taylor";
            checkHostIP = false;
          };
        };
      };
    };
    # security.gnugpg.enable = true;
    shell = {
      mise = {
        enable = true;
        package = pkgs.unstable.mise;
      };
    };
  };
}
