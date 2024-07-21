# nixos specific packages for every system.
{ pkgs, flake-packages, ... }: {
  config = {
    home.packages = with pkgs;
      with flake-packages.${pkgs.system}; [
        byobu
        ncdu
      ];
  };
  }
}
