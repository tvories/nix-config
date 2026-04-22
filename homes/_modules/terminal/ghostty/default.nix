{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.modules.terminal.ghostty;
in
{
  options.modules.terminal.ghostty = {
    enable = lib.mkEnableOption "ghostty";
    package = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      default = if pkgs.stdenv.hostPlatform.isDarwin then pkgs.ghostty-bin else pkgs.ghostty;
      description = "Ghostty package. Uses ghostty-bin on Darwin, ghostty on Linux.";
    };
    fontSize = lib.mkOption {
      type = lib.types.int;
      default = 14;
      description = "Font size";
    };
    extraSettings = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Additional ghostty settings to merge in.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.ghostty = {
      enable = true;
      package = cfg.package;
      enableFishIntegration = config.modules.shell.fish.enable or false;
      settings = lib.mkMerge [
        {
          # Font
          font-family = "JetBrainsMono Nerd Font Mono";
          font-size = cfg.fontSize;

          theme = "dark:Rose Pine,light:Rose Pine Dawn";

          # Window
          window-padding-x = 4;
          window-padding-y = 4;
          window-decoration = if pkgs.stdenv.hostPlatform.isDarwin then "true" else "server";
          confirm-close-surface = false;

          # Misc
          copy-on-select = "clipboard";
          mouse-hide-while-typing = true;
        }
        cfg.extraSettings
      ];
    };
  };
}
