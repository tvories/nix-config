{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.modules.services.restic-server;
in
{
  options.modules.services.restic-server = {
    enable = lib.mkEnableOption "restic-server";
    port = lib.mkOption {
      type = lib.types.int;
      default = 8000;
    };
    restic-path = lib.mkOption {
      type = lib.types.str;
      default = "/restic";
    };
    htpasswd-file = lib.mkOption {
      type = lib.types.path;
      default = ".htpasswd";
    };
    group = lib.mkOption {
      type = lib.types.str;
      default = "";
    };
    user = lib.mkOption {
      type = lib.types.str;
      default = "";
    };
    working-directory = lib.mkOption {
      type = lib.types.path;
      default = "/restic";
    };
    public-cert-file = lib.mkOption {
      type = lib.types.path;
      default = "";
    };
    private-key-file = lib.mkOption {
      type = lib.types.path;
      default = "";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [pkgs.restic-rest-server];
    networking.firewall = {
      allowedTCPPorts = [ cfg.port ];
    };
    systemd.services.restic-server = {
      description = "Restic REST server";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = "${pkgs.restic-rest-server}/bin/rest-server --path ${cfg.restic-path} --htpasswd-file ${cfg.htpasswd-file} --tls  --tls-cert ${cfg.public-cert-file} --tls-key ${cfg.private-key-file} --listen :${toString cfg.port}";
        Restart = "always";
        WorkingDirectory = cfg.working-directory;
        User = cfg.user;
        Group = cfg.group;
      };
    };
  };
}
