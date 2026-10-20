{
  pkgs,
  lib,
  config,
  flake-packages,
  ...
}:
let
  cfg = config.modules.shell.mise;
  tomlFormat = pkgs.formats.toml { };
in
{
  options.modules.shell.mise = {
    enable = lib.mkEnableOption "mise";
    package = lib.mkPackageOption pkgs "mise" { };
    globalConfig = lib.mkOption {
      inherit (tomlFormat) type;
      default = { };
    };
    settings = lib.mkOption {
      inherit (tomlFormat) type;
      default = { };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      cfg.package
      # flake-packages.${pkgs.system}.usage
    ];

    # mise only reads settings from the [settings] table of config.toml;
    # a separate settings.toml is silently ignored.
    xdg.configFile."mise/config.toml".source = tomlFormat.generate "mise-config" (
      cfg.globalConfig
      // {
        settings = {
          experimental = true;
        }
        // cfg.settings;
      }
    );

    programs = {
      bash.initExtra = ''
        eval "$(${lib.getExe cfg.package} activate bash)"
      '';

      fish.shellInit = lib.mkAfter ''
        ${lib.getExe cfg.package} hook-env | source
        ${lib.getExe cfg.package} activate fish | source
      '';
    };
  };
}
