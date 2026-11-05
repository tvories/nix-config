# Taylor's dev workstation setup, shared by the WSL distro and the desktop
# (deskmonster), which replaces it once the dual-boot trial is done.
{
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
        autoLogin.enable = true;
        settings = {
          sync_address = "https://atuin.t-vo.us";
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
      mise = {
        enable = true;
        package = pkgs.unstable.mise;
        # On NixOS mise defaults to compiling runtimes from source, which fails
        # without a dev shell (e.g. Python can't find zlib). nix-ld lets the
        # precompiled builds run instead.
        settings.all_compile = false;
        # Runtimes and tools whose version should follow a project or cluster;
        # repos override these with their own .mise.toml.
        globalConfig.tools = {
          go = "latest";
          node = "lts";
          pnpm = "latest";
          terraform = "latest";
          terragrunt = "latest";
          packer = "latest";
          vault = "latest";
          velero = "latest";
          clusterctl = "latest";
          calicoctl = "latest";
          kube-capacity = "latest";
          crane = "latest";
          # nixpkgs' krr is broken (dependency prometrix) and it isn't on PyPI;
          # Robusta ships it as GitHub release zips with "ubuntu" in the name.
          "github:robusta-dev/krr" = {
            version = "latest";
            asset_pattern = "krr-ubuntu-latest-*.zip";
          };
        };
        globalConfig.shell_alias = {
          tf = "terraform";
        };
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
            IdentityFile = "/home/taylor/.ssh/nixos-root";
            CheckHostIP = "no";
            ForwardAgent = "yes";
          };
          "192.168.1.101" = {
            Port = 22;
            User = "root";
            IdentityFile = "/home/taylor/.ssh/nixos-root";
            CheckHostIP = "no";
            ForwardAgent = "yes";
          };
          "192.168.1.128" = {
            Port = 22;
            User = "root";
            IdentityFile = "/home/taylor/.ssh/nixos-root";
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
          # Key lives in 1Password. The .pub tells the agent which key to sign
          # with; IdentitiesOnly stops it offering all ~10 agent keys, which
          # trips GitHub's ~6-attempt cutoff.
          "github.com" = {
            User = "git";
            IdentityFile = "~/.ssh/taylor_github.pub";
            IdentitiesOnly = "yes";
          };
        };
      };
      # gpg-agent + pinentry for the GPG keys carried over from Ubuntu.
      gnugpg.enable = true;
    };
  };

  # Public half of the 1Password-held GitHub key, for the github.com block above.
  home.file.".ssh/taylor_github.pub".text = ''
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA6CFlucjbbSX98j1saZPFni2pqyoHzGvZ7k7pI53Ngl taylor_github
  '';

  home.packages = with pkgs; [
    # Tools carried over from the Ubuntu distro's Homebrew
    fd
    fzf
    pv
    rclone
    restic
    ansible
    kubernetes-helm
    kustomize
    kubeseal
    kompose
    # logcli, for querying homebox's Loki when the cluster's Grafana is down
    grafana-loki
    # Not in mise's registry
    govc
    # Talos TUI; young 0.1.x project, stable nixpkgs lags behind releases
    unstable.talos-pilot
    # Terminal multiplexer for coding agents; not in stable nixpkgs
    unstable.herdr
    # mise would compile these from source, which is fragile on NixOS
    ruby
    dotnet-sdk
  ];
}
