{ inputs, lib, pkgs, config, outputs, ... }:
{
  imports = [
    ./common/global
  ];

  home = {
    username = lib.mkDefault "tadmin";
    homeDirectory = lib.mkDefault "/Users/${config.home.username}";
    stateVersion = lib.mkDefault "23.11";
    sessionPath = [ "$HOME/.local/bin" ];
  };
}
