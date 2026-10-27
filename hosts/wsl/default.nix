{
  inputs,
  lib,
  pkgs,
  ...
}:
let
  # The full Windows PATH (wsl.interop.includePath) adds ~60 /mnt/c dirs that
  # every command lookup and fish completion scans over the slow 9p bridge.
  # Expose only the Windows tools actually used from the Linux shell.
  windowsTools = {
    "explorer.exe" = "/mnt/c/Windows/explorer.exe";
    "clip.exe" = "/mnt/c/Windows/System32/clip.exe";
    "cmd.exe" = "/mnt/c/Windows/System32/cmd.exe";
    "notepad.exe" = "/mnt/c/Windows/System32/notepad.exe";
    "wsl.exe" = "/mnt/c/Windows/System32/wsl.exe";
    "pwsh.exe" = "/mnt/c/Program Files/PowerShell/7/pwsh.exe";
    "winget.exe" = "/mnt/c/Users/taylor/AppData/Local/Microsoft/WindowsApps/winget.exe";
    "code" = "/mnt/c/Users/taylor/AppData/Local/Programs/Microsoft VS Code/bin/code";
  };
  windowsToolLinks = pkgs.runCommand "windows-tools" { } (
    ''
      mkdir -p $out/bin
    ''
    + pkgs.lib.concatStrings (
      pkgs.lib.mapAttrsToList (name: target: ''
        ln -s ${pkgs.lib.escapeShellArg target} $out/bin/${pkgs.lib.escapeShellArg name}
      '') windowsTools
    )
  );
in
{
  imports = [
    inputs.nixoswsl.nixosModules.wsl
    # Host-specific hardware
    ./hardware-configuration.nix

    #     # Common imports
    # ../common/nixos
    #     ../common/nixos/users/taylor
    # ../common/nixos/users/tadmin
    # ../common/optional/fish.nix
    #     ../common/optional/k3s-server.nix
    #     ../common/optional/nfs-server.nix
    #     # ../common/optional/virtualbox.nix
    #     ../common/optional/samba-server.nix
    #     ../common/optional/zfs.nix
    #     ../common/optional/monitoring.nix

    #     # Secrets

  ];

  config = {
    networking = {
      hostName = "deskmonster";
    };
    boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

    wsl = {
      enable = true;
      interop.register = true;
      # wsl.interop.includePath is a no-op in NixOS-WSL 26.05; this is what
      # actually keeps the Windows PATH out (see windowsTools above).
      wslConf.interop.appendWindowsPath = false;
      defaultUser = "taylor";
      # Bridges Windows' OpenSSH agent pipe (served by 1Password) to
      # $XDG_RUNTIME_DIR/wsl2-ssh-agent.sock and sets SSH_AUTH_SOCK.
      ssh-agent.enable = true;
      docker-desktop.enable = true;
      # Docker Desktop execs plain coreutils by name without a shell, so they
      # must exist in /bin. 4.80 added install/mv (NixOS-WSL #1081, fixed on
      # main only); later versions added test. Cover the usual set at once
      # rather than chasing one error per Docker Desktop release.
      extraBin = map (cmd: { src = "${pkgs.coreutils}/bin/${cmd}"; }) [
        "install"
        "mv"
        "test"
        "mkdir"
        "chmod"
        "chown"
        "rm"
        "ln"
        "cp"
        "stat"
        "id"
        "sleep"
        "readlink"
        "touch"
        "ls"
      ];
    };
    # The bridge exits 0 after a Windows-side timeout (e.g. an unanswered
    # 1Password prompt), which Restart=on-failure ignores, leaving no agent.
    systemd.user.services.wsl2-ssh-agent.serviceConfig = {
      Restart = lib.mkForce "always";
      RestartSec = 1;
    };
    services.openssh = {
      enable = true;
      settings.PasswordAuthentication = false;
    };

    nix.settings.trusted-users = [ "root" "taylor" ];

    programs.nh.flake = "/home/taylor/gits/nix-config";
    # Lets the VS Code Remote server's bundled node binary run (upstream's
    # recommended approach; replaces the old vscode-server patching).
    programs.nix-ld.enable = true;

    # reduce journal size
    services.journald.extraConfig = ''
      SystemMaxUse=5G
    '';

    # Tadmin user
    users.users.taylor = {
      isNormalUser = true;
      shell = pkgs.fish;
      # packages = [ pkgs.home-manager ];
    };

    environment.systemPackages = with pkgs; [
      windowsToolLinks
      wget # VS Code Remote's server install script needs it
      claude-code
      # wget
      # google-cloud-sdk
      powershell
      # _1password
      # google-cloud-sdk
      sops
      python3
      openssl
      nfs-utils
      # nil
      # binfmt
      # libgcc
      gnumake
      gcc
      # libiconv
      # zlib
      # patch
      # bzip2
      # readline
      # sqlite
      # openssl
      # libffi
      # xz
      # tk
      # util-linux
      # gdbm
      # libnsl
      # libuuid
      # libtirpc # libnsl replacement on some systems
      # ncurses # for terminal handling
      # expat # for XML parsing
      libxcrypt
      # nodejs_24
      zlib
      uv
    ];
  };
}
