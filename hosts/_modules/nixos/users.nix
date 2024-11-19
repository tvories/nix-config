{
  config,
  lib,
  ...
}:
let
  cfg = config.modules.users;
in
{
  options.modules.users = {
    groups = lib.mkOption {
      type = lib.types.attrs;
      default = {};
    };
    additionalUsers = lib.mkOption {
      type = lib.types.attrs;
      default = {};
    };
  };

  config.users = {
    inherit (cfg) groups;
    mutableUsers = true;
    users = cfg.additionalUsers;
  };
}
