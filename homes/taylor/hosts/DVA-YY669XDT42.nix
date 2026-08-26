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
        settings = {
          "nas3.mcbadass.local" = {
            ForwardAgent = "yes";
            Port = 22;
            User = "taylor";
            IdentityAgent = opAgentSock;
          };
          "tback.mcbadass.local" = {
            Port = 22;
            User = "taylor";
            IdentityAgent = opAgentSock;
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
            IdentityAgent = opAgentSock;
          };
          "nas-vm.mcbadass.local" = {
            Port = 22;
            User = "taylor";
            IdentityAgent = opAgentSock;
            ForwardAgent = "yes";
          };
          "homebox.mcbadass.local" = {
            Port = 22;
            User = "taylor";
            IdentityAgent = opAgentSock;
            ForwardAgent = "yes";
          };
          "192.168.20.107" = {
            Port = 22;
            User = "tvories";
            IdentityAgent = opAgentSock;
            ForwardAgent = "yes";
          };
        };
      };
      gnugpg.enable = true;
    };
    kubernetes.enable = true;
    terminal.ghostty.enable = true;
  };
}
