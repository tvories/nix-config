{
  pkgs,
  inputs,
  lib,
  config,
  ...
}:
let
  cfg = config.modules.development;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      cue
      alejandra
      _1password-cli
      nixd
      nil
      nixfmt
      statix
      prettier
      pre-commit
      shellcheck
      shfmt
      # yamllint
      unstable.helm-ls
      # Same version as unstable, which marks it insecure (abandoned upstream).
      # Expect 26.11 to flag it too; rclone or awscli2 are the replacements.
      minio-client
      nix-inspect
    ];
  };
}
