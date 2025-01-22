{ pkgs, config, ... }:
let ifTheyExist = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
in
{
  users.groups.service-account = {};
  users.users.svc_scanner = {
    isSystemUser = true;
    group = "service-account";
    extraGroups = [
      ""
    ] ++ ifTheyExist [

      "samba-users"
      "docs-rw"
    ];
  };
}
