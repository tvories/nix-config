{
  users.groups.samba-users = {};

  services.samba-wsdd.enable = true; # make shares visible for windows 10 clients
  services.samba = {
    enable = true;
    openFirewall = true;
    securityType = "user";
    extraConfig = ''
      workgroup = WORKGROUP
      min protocol = SMB2

      browseable = yes
      guest ok = no
      guest account = nobody
      map to guest = bad user
      inherit acls = yes
      map acl inherit = yes
      valid users = @samba-users

      shadow: snapdir = .zfs/snapshot
      shadow: sort = desc

      inherit acls = yes
      map acl inherit = yes

      veto files = /._*/.DS_Store/
      delete veto files = yes

      vfs objects = acl_xattr catia fruit streams_xattr
      fruit:model = MacSamba
      fruit:advertise_fullsync = true
      fruit:metadata = stream
      fruit:aapl = yes
      fruit:veto_appledouble = no
      fruit:zero_file_id = yes
      fruit:posix_rename = yes
      fruit:wipe_intentionally_left_blank_rfork = yes
      fruit:nfs_aces = no
      fruit:delete_empty_adfiles = yes
      spotlight = no
      ea support = yes
    '';
  };
}
