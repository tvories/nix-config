{ inputs, outputs, config, pkgs, lib, home-manager, vscode-server, nixoswsl, ... }:

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

  ]++ (builtins.attrValues {});
  environment.systemPackages = [
    pkgs.wget
    pkgs.google-cloud-sdk
  ];
  networking = {
    hostName = "deskmonster";
  };
  wsl = {
    enable = true;
    defaultUser = "tadmin";
    extraBin = with pkgs; [
      { src = "${coreutils}/bin/uname"; }
      { src = "${coreutils}/bin/dirname"; }
      { src = "${coreutils}/bin/readlink"; }
    ];
  };
  programs.nix-ld.enable = true;
  services.vscode-server.enable = true;
  system.stateVersion = "23.05";
  sops.age.keyFile = "/home/tadmin/.config/sops/age/keys.txt";

  # Tadmin user
  users.users.tadmin = {
    isNormalUser = true;
    shell = pkgs.fish;
    packages = [ pkgs.home-manager ];
  };

  home-manager.users.tadmin = import ../../home-manager/tadmin_${config.networking.hostName}.nix;
}