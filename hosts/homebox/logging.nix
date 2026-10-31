# Central log store for the Talos cluster, outside the cluster so the logs
# survive cluster outages. Talos nodes ship kernel and service logs to Vector
# here, which forwards them to a local Loki. Later, an in-cluster Vector will
# push pod logs straight to Loki, and an in-cluster Grafana will query it.
{
  lib,
  ...
}:
let
  lokiDir = "/var/lib/loki";
  lokiPort = 3100;
  talosKernelPort = 6050;
  talosServicePort = 6051;
  talosNodeNet = "192.168.80.0/24";
  lanNet = "192.168.1.0/24";

  # Talos sends newline-delimited JSON over TCP; Vector records the peer IP in
  # .host.
  talosSource = port: {
    type = "socket";
    mode = "tcp";
    address = "0.0.0.0:${toString port}";
    decoding.codec = "json";
    framing.method = "newline_delimited";
  };

  # One remap per source, so each knows which port its events came in on.
  talosRemap = input: ''
    nodes = {
      "192.168.80.99": "m720q-1",
      "192.168.80.100": "m720q-2",
      "192.168.80.101": "m720q-3",
      "192.168.80.90": "m720q-4"
    }
    node = get(nodes, [to_string(.host) ?? ""]) ?? null
    if node != null {
      .host = node
    }

    ts, err = parse_timestamp(to_string(."talos-time") ?? "", "%+")
    if err == null {
      .timestamp = ts
    }

    # Kernel messages carry no talos-service.
    .service = to_string(."talos-service") ?? "${input}"
    .level = ."talos-level"
    .source = "${input}"
  '';
in
{
  services.loki = {
    enable = true;
    dataDir = lokiDir;
    configuration = {
      auth_enabled = false;
      analytics.reporting_enabled = false;

      server = {
        http_listen_address = "0.0.0.0";
        http_listen_port = lokiPort;
        grpc_listen_address = "127.0.0.1";
        grpc_listen_port = 9095;
      };

      common = {
        path_prefix = lokiDir;
        # Loki's components talk to each other over gRPC at this address, and
        # gRPC only listens on localhost.
        instance_addr = "127.0.0.1";
        replication_factor = 1;
        ring.kvstore.store = "inmemory";
        storage.filesystem = {
          chunks_directory = "${lokiDir}/chunks";
          rules_directory = "${lokiDir}/rules";
        };
      };

      schema_config.configs = [
        {
          from = "2026-10-30";
          store = "tsdb";
          object_store = "filesystem";
          schema = "v13";
          index = {
            prefix = "index_";
            period = "24h";
          };
        }
      ];

      compactor = {
        working_directory = "${lokiDir}/compactor";
        retention_enabled = true;
        delete_request_store = "filesystem";
      };

      limits_config = {
        retention_period = "30d";
        reject_old_samples = true;
        reject_old_samples_max_age = "168h";
        ingestion_rate_mb = 8;
        ingestion_burst_size_mb = 16;
      };

      ruler = {
        storage = {
          type = "local";
          local.directory = "${lokiDir}/rules";
        };
        rule_path = "${lokiDir}/rules-temp";
        alertmanager_url = "https://alert-manager.cluster-0.t-vo.us";
        enable_api = true;
        enable_alertmanager_v2 = true;
      };
    };
  };

  # With auth disabled, Loki's single tenant is named "fake"; log alert rule
  # files go in its directory.
  systemd.tmpfiles.rules = [
    "d ${lokiDir}/rules 0750 loki loki -"
    "d ${lokiDir}/rules/fake 0750 loki loki -"
  ];

  services.vector = {
    enable = true;
    settings = {
      api.enabled = false;
      sources = {
        talos_kernel = talosSource talosKernelPort;
        talos_service = talosSource talosServicePort;
      };
      transforms = {
        talos_remap_kernel = {
          type = "remap";
          inputs = [ "talos_kernel" ];
          source = talosRemap "kernel";
        };
        talos_remap_service = {
          type = "remap";
          inputs = [ "talos_service" ];
          source = talosRemap "service";
        };
      };
      sinks.loki = {
        type = "loki";
        inputs = [
          "talos_remap_kernel"
          "talos_remap_service"
        ];
        endpoint = "http://127.0.0.1:${toString lokiPort}";
        encoding.codec = "json";
        out_of_order_action = "accept";
        # Low-cardinality labels only; everything else stays in the log line.
        labels = {
          job = "talos";
          node = "{{ host }}";
          source = "{{ source }}";
          service = "{{ service }}";
        };
      };
    };
  };

  # Guard against a log flood growing Vector's buffers without bound.
  systemd.services.vector.serviceConfig.MemoryMax = "256M";

  # The ports are reachable only from the networks that use them: Talos nodes
  # send logs; pods (which leave through node IPs) and LAN tools query Loki.
  networking.firewall.extraCommands = lib.concatMapStrings (rule: ''
    iptables -A nixos-fw -p tcp -s ${rule.from} --dport ${toString rule.port} -j nixos-fw-accept
  '') [
    { from = talosNodeNet; port = talosKernelPort; }
    { from = talosNodeNet; port = talosServicePort; }
    { from = talosNodeNet; port = lokiPort; }
    { from = lanNet; port = lokiPort; }
  ];
}
