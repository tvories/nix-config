{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.modules.shell.atuin;
  tomlFormat = pkgs.formats.toml { };
in
{
  options.modules.shell.atuin = {
    enable = lib.mkEnableOption "atuin";
    package = lib.mkPackageOption pkgs "atuin" { };
    flags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
    };
    settings = lib.mkOption {
      inherit (tomlFormat) type;
      default = { };
    };
    autoLogin = {
      enable = lib.mkEnableOption "logging in to the sync server with the key and password from sops";
      username = lib.mkOption {
        type = lib.types.str;
        default = "taylor";
      };
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      programs.atuin = {
        enable = true;
        package = cfg.package;
        flags = cfg.flags;
        settings = cfg.settings;
      };
    }

    # A new machine otherwise generates its own random key on first run and
    # syncs records nobody else can decrypt; this pins the shared key and logs
    # in before that can happen.
    (lib.mkIf cfg.autoLogin.enable {
      sops.secrets = {
        atuin_key = { };
        atuin_password = { };
      };

      programs.atuin.settings.key_path = config.sops.secrets.atuin_key.path;

      systemd.user.services.atuin-login = {
        Unit = {
          Description = "Log in to the atuin sync server";
          After = [ "sops-nix.service" "network-online.target" ];
          Requires = [ "sops-nix.service" ];
        };
        Service = {
          Type = "oneshot";
          # Already logged in is a no-op. The blank line answers the key prompt
          # with "use the existing key file", i.e. key_path above.
          ExecStart = toString (pkgs.writeShellScript "atuin-login" ''
            printf '\n' | ${lib.getExe cfg.package} login \
              --username ${lib.escapeShellArg cfg.autoLogin.username} \
              --password "$(cat ${config.sops.secrets.atuin_password.path})"
          '');
        };
        Install.WantedBy = [ "default.target" ];
      };
    })
  ]);
}
