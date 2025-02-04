{
  config,
  pkgs,
  lib,
  home-manager,
  ...
}:
{

  imports = [ ];

  networking.firewall = {
    allowedTCPPorts = [ 8000 ];
  };

  environment.systemPackages = with pkgs; [
    restic
    restic-rest-server
  ];

  systemd.services.rest-server = {
    description = "Restic REST server";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      ExecStart = "${pkgs.restic-rest-server}/bin/rest-server --path /backup/restic --htpasswd-file .htpasswd --tls  --tls-cert public.cert --tls-key private.key --listen :8000";
      Restart = "always";
      WorkingDirectory = "/home/tback/restic-server";
      User = "tback";
      Group = "65541"; # backup-rw
    };
  };
}
