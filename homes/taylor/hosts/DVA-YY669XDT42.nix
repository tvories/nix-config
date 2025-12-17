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
        matchBlocks = {
          "nas3.mcbadass.local" = {
            forwardAgent = true;
            port = 22;
            user = "taylor";
            extraOptions = {
              "IdentityAgent" = "\"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\"";
            };
          };
          "tback.mcbadass.local" = {
            port = 22;
            user = "taylor";
            extraOptions = {
              "IdentityAgent" = "\"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\"";
            };
            forwardAgent = true;
          };
          "bitbucket.davita.com" = {
            user = "git";
            port = 22;
            identityFile = "~/.ssh/mac-bitbucket";
          };
          "github.com" = {
            user = "git";
            port = 22;
            extraOptions = {
              "IdentityAgent" = "\"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\"";
            };
          };
          "nas-vm.mcbadass.local" = {
            port = 22;
            user = "taylor";
            extraOptions = {
              "IdentityAgent" = "\"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\"";
            };
            forwardAgent = true;
          };
          "homebox.mcbadass.local" = {
            port = 22;
            user = "taylor";
            extraOptions = {
              "IdentityAgent" = "\"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\"";
            };
            forwardAgent = true;
          };
          "192.168.20.107" = {
            port = 22;
            user = "tvories";
            extraOptions = {
              "IdentityAgent" = "\"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\"";
            };
            forwardAgent = true;
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
