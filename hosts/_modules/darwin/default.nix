{
  ...
}:
{
  imports = [
    ./fonts.nix
    ./homebrew.nix
    ./nix.nix
    ./os-defaults.nix
    ./packages.nix
  ];

  system = {
    stateVersion = 4; # nix-darwin stateVersion
    primaryUser = "tvories";
  };
}
