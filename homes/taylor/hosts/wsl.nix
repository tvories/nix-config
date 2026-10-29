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
          # Key lives in 1Password (reached via wsl.ssh-agent). The .pub tells the
          # agent which key to sign with; IdentitiesOnly stops it offering all
          # ~10 agent keys, which trips GitHub's ~6-attempt cutoff.
          "github.com" = {
            User = "git";
            IdentityFile = "~/.ssh/taylor_github.pub";
            IdentitiesOnly = "yes";
          };
        };
      };
    };
    # gpg-agent + pinentry for the GPG keys carried over from Ubuntu.
    security.gnugpg.enable = true;
    shell = {
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
  };

  # SSH agent: provided system-wide by wsl.ssh-agent (hosts/wsl/default.nix).

  # Public half of the 1Password-held GitHub key, for the github.com block above.
  home.file.".ssh/taylor_github.pub".text = ''
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA6CFlucjbbSX98j1saZPFni2pqyoHzGvZ7k7pI53Ngl taylor_github
  '';

  # The full Windows PATH is off (wsl.conf appendWindowsPath=false), but System32
  # alone is cheap (~1 ms per missed lookup over 9p vs ~60 ms for the whole
  # Windows PATH). Appended so Linux commands always win.
  programs.fish.interactiveShellInit = ''
    fish_add_path --append --path /mnt/c/Windows/System32
  '';

  # Docker Desktop runs the engine and exposes /var/run/docker.sock here, but
  # only shares a bare `docker` binary in /usr/bin (not on NixOS's PATH) and no
  # compose/buildx plugins. Use the Nix client and register the plugins where
  # the docker CLI looks for them.
  home.packages = with pkgs; [
    docker-client

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
    # Not in mise's registry
    govc
    # Talos TUI; young 0.1.x project, stable nixpkgs lags behind releases
    unstable.talos-pilot
    # mise would compile these from source, which is fragile on NixOS
    ruby
    dotnet-sdk
  ];
  home.file.".docker/cli-plugins/docker-compose".source =
    "${pkgs.docker-compose}/libexec/docker/cli-plugins/docker-compose";
  home.file.".docker/cli-plugins/docker-buildx".source =
    "${pkgs.docker-buildx}/libexec/docker/cli-plugins/docker-buildx";
}
