{ pkgs, ... }:
{
  imports = [
    ./atuin.nix
    ./fish.nix
    ./starship.nix
    ./neovim.nix
  ];
  home.packages = with pkgs; [
    lsd
    zoxide
    tree
  ];
}
