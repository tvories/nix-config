{
  pkgs,
  ...
}:
{
  imports = [ ./_workstation.nix ];

  # SSH agent: provided system-wide by wsl.ssh-agent (hosts/wsl/default.nix).

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
  home.packages = [ pkgs.docker-client ];
  home.file.".docker/cli-plugins/docker-compose".source =
    "${pkgs.docker-compose}/libexec/docker/cli-plugins/docker-compose";
  home.file.".docker/cli-plugins/docker-buildx".source =
    "${pkgs.docker-buildx}/libexec/docker/cli-plugins/docker-buildx";
}
