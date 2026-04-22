# nixos specific packages for every system.
{ pkgs, flake-packages, ... }:
{
  config = {
    programs.nh = {
      enable = true;
      clean.enable = true;
      clean.extraArgs = "--keep-since 4d --keep 3";
    };

    environment.systemPackages =
      with pkgs;
      with flake-packages.${pkgs.stdenv.hostPlatform.system};
      [
        byobu
        comma
        ncdu
      ];
  };
}
