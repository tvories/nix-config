{ config, pkgs, lib, home-manager, vscode-server, nixoswsl, ... }:

{
  imports = [
      # Host-specific hardware
      ./hardware-configuration.nix

  #     # Common imports
    ../common/nixos
  #     ../common/nixos/users/taylor
  #     ../common/nixos/users/tadmin
  #     ../common/optional/fish.nix
  #     ../common/optional/k3s-server.nix
  #     ../common/optional/nfs-server.nix
  #     # ../common/optional/virtualbox.nix
  #     ../common/optional/samba-server.nix
  #     ../common/optional/zfs.nix
  #     ../common/optional/monitoring.nix

  #     # Secrets
      
  ];
  environment.systemPackages = [
    pkgs.wget
  ];
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
}