{ pkgs, flake-packages, ... }:
{
  config = {
    home.packages =
      with pkgs;
      with flake-packages.${pkgs.stdenv.hostPlatform.system};
      [
        any-nix-shell
        binutils
        coreutils
        curl
        dust
        envsubst
        findutils
        fish
        gawk
        gnused
        gum
        jo
        jq
        shcopy
        tmux
        vim
        wget
        yq-go
        tree
        # vault
        inetutils
      ];
  };
}
