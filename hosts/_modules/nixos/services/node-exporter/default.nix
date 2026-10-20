{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.modules.services.node-exporter;
  textfileDir = "/var/lib/prometheus-node-exporter-text";

  # NixOS keeps /run/booted-system (what we booted) and /run/current-system
  # (latest switch). A reboot is needed when the boot-time pieces differ.
  # systemd is compared against the running PID 1 instead, because a switch
  # re-execs systemd in place without a reboot.
  rebootRequiredScript = pkgs.writeShellScript "node-reboot-required" ''
    set -u
    export PATH=${lib.makeBinPath [ pkgs.coreutils ]}
    dir="''${TEXTFILE_DIR:-${textfileDir}}"
    required=0
    lines=""

    component() {
      local name=$1 running=$2 current=$3 changed=0
      if [ -n "$running" ] && [ -n "$current" ] && [ "$running" != "$current" ]; then
        changed=1
        required=1
      fi
      lines+="node_reboot_required_component{component=\"$name\"} $changed"$'\n'
    }

    for c in kernel initrd kernel-modules; do
      component "$c" "$(readlink -f /run/booted-system/$c 2>/dev/null)" "$(readlink -f /run/current-system/$c 2>/dev/null)"
    done
    component systemd "$(readlink -f /proc/1/exe 2>/dev/null)" \
      "$(readlink -f /run/current-system/systemd/lib/systemd/systemd 2>/dev/null)"

    {
      echo "# HELP node_reboot_required 1 if the running kernel, initrd or systemd is older than the current NixOS generation."
      echo "# TYPE node_reboot_required gauge"
      echo "node_reboot_required $required"
      echo "# HELP node_reboot_required_component 1 if this component differs between the running system and the current generation."
      echo "# TYPE node_reboot_required_component gauge"
      printf '%s' "$lines"
    } > "$dir/reboot_required.prom.tmp"
    mv "$dir/reboot_required.prom.tmp" "$dir/reboot_required.prom"
  '';
in
{
  options.modules.services.node-exporter = {
    enable = lib.mkEnableOption "node-exporter";
    port = lib.mkOption {
      type = lib.types.int;
      default = 9100;
    };
    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Open the exporter port in the firewall";
    };
    enabledCollectors = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Collectors to enable on top of node-exporter's defaults";
    };
    systemdUnits = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [
        "sshd"
        "docker"
      ];
      description = ''
        Service names (without .service) the systemd collector exports.
        Empty exports every unit.
      '';
    };
    rebootRequired = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Export node_reboot_required via the textfile collector";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        services.prometheus.exporters.node = {
          enable = true;
          inherit (cfg) port openFirewall enabledCollectors;
          # node-exporter anchors this regex. [.] instead of \. because the flag
          # lands unquoted in ExecStart, where systemd would mangle a backslash.
          extraFlags =
            lib.optional (cfg.systemdUnits != [ ])
              "--collector.systemd.unit-include=(${lib.concatStringsSep "|" cfg.systemdUnits})[.]service"
            ++ lib.optional cfg.rebootRequired "--collector.textfile.directory=${textfileDir}";
        };
      }
      (lib.mkIf cfg.rebootRequired {
        systemd.tmpfiles.rules = [ "d ${textfileDir} 0755 root root -" ];

        systemd.services.node-reboot-required = {
          description = "Write node_reboot_required for the node-exporter textfile collector";
          serviceConfig = {
            Type = "oneshot";
            ExecStart = rebootRequiredScript;
          };
        };

        systemd.timers.node-reboot-required = {
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnBootSec = "2min";
            OnUnitActiveSec = "15min";
          };
        };
      })
    ]
  );
}
