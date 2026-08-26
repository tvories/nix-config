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
    editor = {
      vscode = {
        enable = true;
        userSettings = lib.importJSON ../config/editor/vscode/settings.json;
      };
    };
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
        email = "taylor.vories@davita.com";
      };
    };
    security = {
      ssh = {
        enable = true;
        settings = {
          "nas3.mcbadass.local" = {
            ForwardAgent = "yes";
            Port = 22;
            User = "taylor";
            IdentityAgent = "\"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\"";
          };
          "tback.mcbadass.local" = {
            Port = 22;
            User = "taylor";
            IdentityAgent = "\"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\"";
            ForwardAgent = "yes";
          };
          "bitbucket.davita.com" = {
            User = "git";
            Port = 22;
            IdentityFile = "~/.ssh/mac-bitbucket";
          };
          "github.com" = {
            User = "git";
            Port = 22;
            IdentityAgent = "\"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\"";
          };
          "nas-vm.mcbadass.local" = {
            Port = 22;
            User = "taylor";
            IdentityAgent = "\"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\"";
            ForwardAgent = "yes";
          };
        };
      };
    };
    kubernetes.enable = true;
    security.gnugpg.enable = true;
    shell = {
      mise = {
        enable = true;
        package = pkgs.unstable.mise;
      };
    };
  };
}
