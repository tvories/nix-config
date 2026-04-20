{
  lib,
  pkgs,
  ...
}:
let
  opAgentSock = "\"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\"";
in
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
      mise = {
        enable = true;
        package = pkgs.unstable.mise;
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
              "IdentityAgent" = opAgentSock;
            };
          };
          "tback.mcbadass.local" = {
            port = 22;
            user = "taylor";
            extraOptions = {
              "IdentityAgent" = opAgentSock;
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
              "IdentityAgent" = opAgentSock;
            };
          };
          "nas-vm.mcbadass.local" = {
            port = 22;
            user = "taylor";
            extraOptions = {
              "IdentityAgent" = opAgentSock;
            };
            forwardAgent = true;
          };
          "homebox.mcbadass.local" = {
            port = 22;
            user = "taylor";
            extraOptions = {
              "IdentityAgent" = opAgentSock;
            };
            forwardAgent = true;
          };
          "192.168.20.107" = {
            port = 22;
            user = "tvories";
            extraOptions = {
              "IdentityAgent" = opAgentSock;
            };
            forwardAgent = true;
          };
        };
      };
      gnugpg.enable = true;
    };
    kubernetes.enable = true;
    terminal.ghostty.enable = true;
  };
}
