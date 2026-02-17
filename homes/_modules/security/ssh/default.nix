{
  config,
  lib,
  ...
}:
let
  cfg = config.modules.security.ssh;
in
{
  options.modules.security.ssh = {
    enable = lib.mkEnableOption "ssh";
    matchBlocks = lib.mkOption {
      type = lib.types.attrs;
      default = { };
    };
  };

  config = lib.mkIf cfg.enable {
    # Ensure ~/.ssh directory has correct permissions
    home.file.".ssh/control/.keep".text = "";

    programs.ssh = {
      enable = true;
      inherit (cfg) matchBlocks;

      controlMaster = "auto";
      controlPath = "~/.ssh/control/%C";

      includes = [
        "config.d/*"
      ];
    };

    # Force the config to be a real file instead of a symlink
    # This fixes "Bad owner or permissions" errors
    home.activation.fixSshPermissions = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ -L "$HOME/.ssh/config" ]; then
        $DRY_RUN_CMD cp -L "$HOME/.ssh/config" "$HOME/.ssh/config.tmp"
        $DRY_RUN_CMD rm "$HOME/.ssh/config"
        $DRY_RUN_CMD mv "$HOME/.ssh/config.tmp" "$HOME/.ssh/config"
      fi
      $DRY_RUN_CMD chmod 600 "$HOME/.ssh/config"
    '';
  };
}
