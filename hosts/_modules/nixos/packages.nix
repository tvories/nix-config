# nixos specific packages for every system.
{ pkgs, flake-packages, ... }:
{
  config = {
    environment.systemPackages =
      with pkgs;
      with flake-packages.${pkgs.system};
      [
        byobu
        ncdu
      ];
  };
}
