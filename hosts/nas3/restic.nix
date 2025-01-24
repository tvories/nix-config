{
  config,
  pkgs,
  lib,
  ...
}:

let
  backupConfig = [
    {
      name = "photos";
      source = "/ook/Photos";
      tag = "nas3-photos";
      timer = "1:00:00";
    }
    {
      name = "documents";
      source = "/ook/Documents";
      tag = "nas3-documents";
      timer = "0:00:00";
    }
    {
      name = "k8s";
      source = "/ook/k8s";
      tag = "nas3-k8s";
      timer = "2:00:00";
    }
    {
      name = "minio";
      source = "/ook/minio";
      tag = "nas3-minio";
      timer = "3:00:00";
    }
    {
      name = "backups";
      source = "/ook/Backup";
      tag = "nas3-backups";
      timer = "4:00:00";
    }
  ];

  # Define restic endpoints
  resticEndpoints = [
    {
      name = "tback";
      cert = "/home/taylor/restic/tback-rest.cert";
      base = "$RESTIC_REPOSITORY_BASE";
    }
    {
      name = "deskmonster";
      cert = "/home/taylor/restic/deskmonster-rest.cert";
      base = "$RESTIC_DESKMONSTER_BASE";
    }
  ];

in
{
  # Create systemd services and timers for each backup config
  systemd.services = lib.mkMerge (
    map (config: {
      "restic-backup-${config.name}" = {
        description = "Restic backup service ${config.name}";
        script = lib.concatStringsSep "\n" (
          map (endpoint: ''
            source /home/taylor/restic/.restic-env;
            ${pkgs.restic}/bin/restic backup --cacert ${endpoint.cert} -q ${config.source} --tag ${config.tag} -r ${endpoint.base}/${config.name};
            ${pkgs.restic}/bin/restic forget --cacert ${endpoint.cert} -q --prune --keep-hourly 24 --keep-daily 7 -r ${endpoint.base}/${config.name}
          '') resticEndpoints
        );
        serviceConfig = {
          Type = "oneshot";
          User = "root";
        };
      };
    }) backupConfig
  );

  systemd.timers = lib.mkMerge (
    map (config: {
      "restic-backup-${config.name}" = {
        description = "Restic backup timer ${config.name}";
        timerConfig = {
          OnCalendar = config.timer;
          Persistent = true;
        };
        wantedBy = [ "timers.target" ];
      };
    }) backupConfig
  );
}
