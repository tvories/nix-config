{ config, pkgs, lib, home-manager, ... }: {

  imports = [ ];

  networking.firewall = {
    allowedTCPPorts = [ 8000 ];
  };

  systemd.services.rest-server = {
    description = "Restic REST server";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      ExecStart = "${pkgs.restic-rest-server}/bin/rest-server --path /backup/sda1/restic --htpasswd-file .htpasswd --tls  --tls-cert public_key --tls-key private_key --listen :8000";
      Restart = "always";
      WorkingDirectory = "/home/tback/restic-server";
      User = "tback";
      Group = "65541"; # backup-rw
    };
  };
}