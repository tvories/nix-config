{ config, pkgs, lib, ... }:
{
  environment.systemPackages = [
    pkgs.tmux
    pkgs.powershell
    pkgs.bat
    pkgs.fluxcd
    pkgs.jq
    pkgs.k9s
    pkgs.kubecolor
    pkgs.restic
    pkgs.yq
    pkgs.vault
    pkgs.minio-client
    pkgs.python3
    pkgs.byobu
    pkgs.btop
    pkgs.minio-client
    pkgs.dig
    pkgs.inetutils
    pkgs.restic
    pkgs.ncdu
  ];

  programs.mtr.enable = true;
}
