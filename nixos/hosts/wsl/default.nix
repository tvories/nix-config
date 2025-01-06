{
  inputs,
  outputs,
  config,
  pkgs,
  lib,
  home-manager,
  vscode-server,
  nixoswsl,
  ...
}:

{
  imports = [
    inputs.vscode-server.nixosModules.default
    inputs.nixoswsl.nixosModules.wsl
    # Host-specific hardware
    ./hardware-configuration.nix

    #     # Common imports
    ../common/nixos
    #     ../common/nixos/users/taylor
    # ../common/nixos/users/tadmin
    ../common/optional/fish.nix
    #     ../common/optional/k3s-server.nix
    #     ../common/optional/nfs-server.nix
    #     # ../common/optional/virtualbox.nix
    #     ../common/optional/samba-server.nix
    #     ../common/optional/zfs.nix
    #     ../common/optional/monitoring.nix

    #     # Secrets

  ] ++ (builtins.attrValues { });
  environment.systemPackages = [
    pkgs.wget
    pkgs.google-cloud-sdk
    pkgs.powershell
    pkgs._1password-cli
    pkgs.google-cloud-sdk
    pkgs.sops
    pkgs.nfs-utils
    pkgs.nil
    # pkgs.binfmt
  ];
  networking = {
    hostName = "deskmonster";
  };
  wsl = {
    enable = true;
    defaultUser = "tadmin";
    # interop.register = true;
    extraBin = with pkgs; [
      { src = "${coreutils}/bin/uname"; }
      { src = "${coreutils}/bin/dirname"; }
      { src = "${coreutils}/bin/readlink"; }
    ];
  };
  nixpkgs.config.permittedInsecurePackages = [
    "vault-1.14.10"
  ];

  # WSL screams if you try to enable rpcbind. disabling and using nfsv4 appears to solve the issue
  # services.rpcbind.enable = lib.mkForce false;
  # fileSystems."/mnt/nfs/nas3" = {
  #   device = "192.168.1.24:/ook";
  #   fsType = "nfs";
  #   options = [ "nfsvers=4.2" ];
  # };

  programs.nix-ld.enable = true;
  services.vscode-server.enable = true;
  system.stateVersion = "24.05";
  sops.age.keyFile = "/home/tadmin/.config/sops/age/keys.txt";

  # Tadmin user
  users.users.tadmin = {
    isNormalUser = true;
    shell = pkgs.fish;
    packages = [ pkgs.home-manager ];
  };

  home-manager.users.tadmin = import ../../home-manager/tadmin_${config.networking.hostName}.nix;

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
}
