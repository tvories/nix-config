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
  ];
}
