{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.modules.services.technitium;
in
{
  options.modules.services.technitium = {
    enable = lib.mkEnableOption "Technitium DNS Server";

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/technitium";
      description = "Directory to store Technitium DNS Server data";
    };

    webPort = lib.mkOption {
      type = lib.types.port;
      default = 5380;
      description = "Port for the web interface";
    };

    dnsPort = lib.mkOption {
      type = lib.types.port;
      default = 53;
      description = "Port for DNS service";
    };

    dhcpPort = lib.mkOption {
      type = lib.types.port;
      default = 67;
      description = "Port for DHCP service";
    };

    clusterPort = lib.mkOption {
      type = lib.types.port;
      default = 53443;
      description = "Port for cluster service";
    };

    enableDhcp = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable DHCP server functionality";
    };

    domain = lib.mkOption {
      type = lib.types.str;
      default = "dns.local";
      description = "DNS server domain name";
      example = "dns.mcbadass.local";
    };

    image = lib.mkOption {
      type = lib.types.str;
      default = "technitium/dns-server:latest";
      description = "Docker image to use for Technitium DNS Server";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Open firewall ports for DNS, DHCP, and web interface";
    };

    traefik = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable Traefik routing for Technitium web interface";
      };

      host = lib.mkOption {
        type = lib.types.str;
        default = "dns.${cfg.domain}";
        description = "Hostname for Traefik routing";
        example = "dns.t-vo.us";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers = {
      backend = "docker";
      containers = {
        technitium = {
          image = cfg.image;
          ports = [
            "${toString cfg.webPort}:5380"
            "${toString cfg.dnsPort}:53/tcp"
            "${toString cfg.dnsPort}:53/udp"
            "${toString cfg.clusterPort}:53443/tcp"
          ]
          ++ lib.optionals cfg.enableDhcp [
            "${toString cfg.dhcpPort}:67/udp"
          ];
          autoStart = true;
          environment = {
            DNS_SERVER_DOMAIN = cfg.domain;
          };
          volumes = [
            "${cfg.dataDir}:/etc/dns"
          ];
          extraOptions = lib.optionals cfg.enableDhcp [
            "--network=host" # Required for DHCP to work properly
          ];
        };
      };
    };

    # Ensure the data directory exists
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 root root -"
    ];

    # Open firewall ports if enabled
    networking.firewall = lib.mkIf cfg.openFirewall {
      allowedTCPPorts = [
        cfg.dnsPort
        cfg.webPort
        cfg.clusterPort
      ];
      allowedUDPPorts = [
        cfg.dnsPort
      ]
      ++ lib.optionals cfg.enableDhcp [
        cfg.dhcpPort
      ];
    };

    # Traefik configuration
    modules.services.traefik = lib.mkIf cfg.traefik.enable {
      routers.technitium = {
        rule = "Host(`${cfg.traefik.host}`)";
        service = "technitium";
      };

      services.technitium = {
        url = "http://localhost:${toString cfg.webPort}";
      };
    };
  };
}
