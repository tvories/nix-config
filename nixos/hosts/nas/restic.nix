{ config, pkgs, lib, home-manager, ... }:

{
  imports = [];

  # Automated backups and cleanup
  
  # Photos
  systemd.services."restic-backup-photos" = {
    description = "Restic backup service Photos";
    script = ''
      source /home/taylor/restic/.restic-env;
      ${pkgs.restic}/bin/restic backup --cacert /home/taylor/restic/tback-rest.cert -q /ook/Photos --tag nas3-photos -r $RESTIC_REPOSITORY_BASE/photos;
      ${pkgs.restic}/bin/restic forget --cacert /home/taylor/restic/tback-rest.cert -q --prune --keep-hourly 24 --keep-daily 7 -r $RESTIC_REPOSITORY_BASE/photos
      ${pkgs.restic}/bin/restic backup --cacert /home/taylor/restic/deskmonster-rest.cert -q /ook/Photos --tag nas3-photos -r $RESTIC_DESKMONSTER_BASE/photos;
      ${pkgs.restic}/bin/restic forget --cacert /home/taylor/restic/deskmonster-rest.cert -q --prune --keep-hourly 24 --keep-daily 7 -r $RESTIC_DESKMONSTER_BASE/photos
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
  };

  systemd.timers."restic-backup-photos" = {
    description = "Restic backup timer Photos";
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
    wantedBy = [ "timers.target" ];
  };

  # Documents
  systemd.services."restic-backup-documents" = {
    description = "Restic backup service Documents";
    script = ''
      source /home/taylor/restic/.restic-env;
      ${pkgs.restic}/bin/restic backup --cacert /home/taylor/restic/tback-rest.cert -q /ook/Documents --tag nas3-documents -r $RESTIC_REPOSITORY_BASE/documents;
      ${pkgs.restic}/bin/restic forget --cacert /home/taylor/restic/tback-rest.cert -q --prune --keep-hourly 24 --keep-daily 7 -r $RESTIC_REPOSITORY_BASE/documents
      ${pkgs.restic}/bin/restic backup --cacert /home/taylor/restic/deskmonster-rest.cert -q /ook/Documents --tag nas3-documents -r $RESTIC_DESKMONSTER_BASE/documents;
      ${pkgs.restic}/bin/restic forget --cacert /home/taylor/restic/deskmonster-rest.cert -q --prune --keep-hourly 24 --keep-daily 7 -r $RESTIC_DESKMONSTER_BASE/documents
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
  };

  systemd.timers."restic-backup-documents" = {
    description = "Restic backup timer Documents";
    timerConfig = {
      OnCalendar = "2:00:00";
      Persistent = true;
    };
    wantedBy = [ "timers.target" ];
  };

  # k8s
  systemd.services."restic-backup-k8s" = {
    description = "Restic backup service k8s";
    script = ''
      source /home/taylor/restic/.restic-env;
      ${pkgs.restic}/bin/restic backup --cacert /home/taylor/restic/tback-rest.cert -q /ook/k8s --tag nas3-k8s -r $RESTIC_REPOSITORY_BASE/k8s;
      ${pkgs.restic}/bin/restic forget --cacert /home/taylor/restic/tback-rest.cert -q --prune --keep-hourly 24 --keep-daily 7 -r $RESTIC_REPOSITORY_BASE/k8s
      ${pkgs.restic}/bin/restic backup --cacert /home/taylor/restic/deskmonster-rest.cert -q /ook/k8s --tag nas3-k8s -r $RESTIC_DESKMONSTER_BASE/k8s;
      ${pkgs.restic}/bin/restic forget --cacert /home/taylor/restic/deskmonster-rest.cert -q --prune --keep-hourly 24 --keep-daily 7 -r $RESTIC_DESKMONSTER_BASE/k8s
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
  };

  systemd.timers."restic-backup-k8s" = {
    description = "Restic backup timer k8s";
    timerConfig = {
      OnCalendar = "2:00:00";
      Persistent = true;
    };
    wantedBy = [ "timers.target" ];
  };

  # minio
  systemd.services."restic-backup-minio" = {
    description = "Restic backup service minio";
    script = ''
      source /home/taylor/restic/.restic-env;
      ${pkgs.restic}/bin/restic backup --cacert /home/taylor/restic/tback-rest.cert -q /ook/minio --tag nas3-minio -r $RESTIC_REPOSITORY_BASE/minio;
      ${pkgs.restic}/bin/restic forget --cacert /home/taylor/restic/tback-rest.cert -q --prune --keep-hourly 24 --keep-daily 7 -r $RESTIC_REPOSITORY_BASE/minio
      ${pkgs.restic}/bin/restic backup --cacert /home/taylor/restic/deskmonster-rest.cert -q /ook/minio --tag nas3-minio -r $RESTIC_DESKMONSTER_BASE/minio;
      ${pkgs.restic}/bin/restic forget --cacert /home/taylor/restic/deskmonster-rest.cert -q --prune --keep-hourly 24 --keep-daily 7 -r $RESTIC_DESKMONSTER_BASE/minio
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
  };

  systemd.timers."restic-backup-minio" = {
    description = "Restic backup timer minio";
    timerConfig = {
      OnCalendar = "3:00:00";
      Persistent = true;
    };
    wantedBy = [ "timers.target" ];
  };

  # backups
  systemd.services."restic-backup-backups" = {
    description = "Restic backup service backup folder";
    script = ''
      source /home/taylor/restic/.restic-env;
      ${pkgs.restic}/bin/restic backup --cacert /home/taylor/restic/tback-rest.cert -q /ook/Backup --tag nas3-backups -r $RESTIC_REPOSITORY_BASE/backups;
      ${pkgs.restic}/bin/restic forget --cacert /home/taylor/restic/tback-rest.cert -q --prune --keep-hourly 24 --keep-daily 7 -r $RESTIC_REPOSITORY_BASE/backups
      ${pkgs.restic}/bin/restic backup --cacert /home/taylor/restic/deskmonster-rest.cert -q /ook/Backup --tag nas3-backups -r $RESTIC_DESKMONSTER_BASE/backups;
      ${pkgs.restic}/bin/restic forget --cacert /home/taylor/restic/deskmonster-rest.cert -q --prune --keep-hourly 24 --keep-daily 7 -r $RESTIC_DESKMONSTER_BASE/backups
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
  };

  systemd.timers."restic-backup-backups" = {
    description = "Restic backup timer backups folder";
    timerConfig = {
      OnCalendar = "3:00:00";
      Persistent = true;
    };
    wantedBy = [ "timers.target" ];
  };
}