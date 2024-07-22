{ lib, config, ... }:
let
  cfg = config.modules.services.msmtp;
in
{
  options.modules.services.msmtp = {
    enable = lib.mkEnableOption "msmtp";
    exports = lib.mkOption {
      type = lib.types.str;
      default = "";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.msmtp = {
      enable = true;
      accounts.default = {
        host = "smtp-relay.mcbadass.local";
        from = "${config.networking.hostName}@t-vo.us";
      };
      defaults = {
        aliases = "/etc/aliases";
      };
    };
    environment.etc = {
      "aliases" = {
        text = ''
          root: ${config.networking.hostName}@t-vo.us
        '';
        mode = "0644";
      };
    };
  };
}
