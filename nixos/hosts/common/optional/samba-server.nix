{
  users.groups.samba-users = {};

  services.samba-wsdd.enable = true; # make shares visible for windows 10 clients
  services.samba = {
    enable = true;
    openFirewall = true;
    securityType = "user";
    extraConfig = ''
      min protocol = SMB2
      workgroup = WORKGROUP

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

      ea support = yes
      vfs objects = fruit streams_xattr
      fruit:aapl = yes
      fruit:metadata = stream
      fruit:model = MacSamba
      fruit:posix_rename = yes
      fruit:veto_appledouble = no
      fruit:nfs_aces = no
      fruit:wipe_intentionally_left_blank_rfork = yes
      fruit:delete_empty_adfiles = yes
      spotlight = no
    '';
  };
}
