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
        settings = {
          "tback.mcbadass.local" = {
            Port = 22;
            User = "taylor";
            IdentityFile = "/home/taylor/.ssh/taylor-1pw-key";
            CheckHostIP = "no";
            ForwardAgent = "yes";
          };
          "homebox.mcbadass.local" = {
            Port = 22;
            User = "taylor";
            IdentityFile = "/home/taylor/.ssh/taylor-1pw-key";
            CheckHostIP = "no";
            ForwardAgent = "yes";
          };
          "nas-vm.mcbadass.local" = {
            Port = 22;
            User = "taylor";
            IdentityFile = "/home/taylor/.ssh/taylor-1pw-key";
            CheckHostIP = "no";
            ForwardAgent = "yes";
          };
          "192.168.1.97" = {
            Port = 22;
            User = "root";
            IdentityFile = "/home/taylor/nixos-root";
            CheckHostIP = "no";
            ForwardAgent = "yes";
          };
          "192.168.1.101" = {
            Port = 22;
            User = "root";
            IdentityFile = "/home/taylor/nixos-root";
            CheckHostIP = "no";
            ForwardAgent = "yes";
          };
          "192.168.1.128" = {
            Port = 22;
            User = "root";
            IdentityFile = "/home/taylor/nixos-root";
            CheckHostIP = "no";
            ForwardAgent = "yes";
          };
          "nas3.mcbadass.local" = {
            Port = 22;
            User = "taylor";
            IdentityFile = "/home/taylor/.ssh/taylor-1pw-key";
            CheckHostIP = "no";
            ForwardAgent = "yes";
          };
          "192.168.1.230" = {
            # nas-vm ip
            Port = 22;
            User = "root";
            IdentityFile = "/home/taylor/.ssh/nixos-root";
            CheckHostIP = "no";
            ForwardAgent = "yes";
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

  home.sessionVariables = {
    NIX_SSH = "ssh.exe";
  };
}
