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

  home.packages = [ pkgs.socat ];

  # Bridge the Windows-side 1Password SSH agent (exposed as a named pipe,
  # which ssh.exe on Windows already talks to) into a Unix socket so the
  # WSL-side ssh client (used by nh/nixos-rebuild for remote deploys) can
  # authenticate through it too, without a private key on disk.
  programs.fish.interactiveShellInit = ''
    set -gx SSH_AUTH_SOCK "$HOME/.1password/agent.sock"
    if not test -S $SSH_AUTH_SOCK
      mkdir -p (dirname $SSH_AUTH_SOCK)
      rm -f $SSH_AUTH_SOCK
      setsid nohup socat UNIX-LISTEN:$SSH_AUTH_SOCK,fork EXEC:"npiperelay.exe -ei -s //./pipe/openssh-ssh-agent",nofork >/tmp/1password-ssh-relay.log 2>&1 &
      disown
    end
  '';
}
