{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.modules.services.traefik;
in
{
  options.modules.services.traefik = {
    enable = lib.mkEnableOption "traefik";

    domain = lib.mkOption {
      type = lib.types.str;
      description = "Main domain for SSL certificate";
      example = "t-vo.us";
    };

    sans = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Subject Alternative Names for SSL certificate";
      example = ["*.t-vo.us" "uptime-kuma.t-vo.us"];
    };

    dashboardHost = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Hostname for traefik dashboard (null to disable)";
      example = "tback.t-vo.us";
    };

    routers = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          rule = lib.mkOption {
            type = lib.types.str;
            description = "Router rule (e.g., Host(`subdomain.t-vo.us`))";
          };
          service = lib.mkOption {
            type = lib.types.str;
            description = "Service name to route to";
          };
          middlewares = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
            description = "List of middleware names to apply";
          };
          entrypoints = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = ["websecure"];
            description = "Entry points for this router";
          };
          tls = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Enable TLS for this router";
          };
        };
      });
      default = {};
      description = "HTTP routers configuration";
    };

    services = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          url = lib.mkOption {
            type = lib.types.str;
            description = "Backend service URL";
            example = "http://localhost:8080";
          };
        };
      });
      default = {};
      description = "HTTP services configuration";
    };

    middlewares = lib.mkOption {
      type = lib.types.attrsOf lib.types.attrs;
      default = {};
      description = "HTTP middlewares configuration";
      example = {
        auth = {
          basicAuth = {
            usersFile = "/path/to/users";
          };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.cf-email = {
      sopsFile = ./secret.sops.yaml;
      owner = config.systemd.services.traefik.serviceConfig.User;
    };
    sops.secrets.cf-token = {
      sopsFile = ./secret.sops.yaml;
      owner = config.systemd.services.traefik.serviceConfig.User;
    };
    sops.secrets.traefik-auth-file = {
      sopsFile = ./secret.sops.yaml;
      owner = config.systemd.services.traefik.serviceConfig.User;
    };

    systemd.services.traefik.environment = {
      CF_API_EMAIL_FILE = "${config.sops.secrets.cf-email.path}";
      CF_API_KEY_FILE = "${config.sops.secrets.cf-token.path}";
    };

    services.traefik = {
      enable = true;
      staticConfigOptions = {
        entryPoints = {
          web = {
            address = ":80";
            asDefault = true;
            http.redirections.entrypoint = {
              to = "websecure";
              scheme = "https";
            };
          };
          websecure = {
            address = ":443";
            asDefault = true;
            http.tls = {
              certResolver = "cloudflare";
              domains = [
                {
                  main = cfg.domain;
                  sans = cfg.sans;
                }
              ];
            };
          };
        };

        log = {
          level = "DEBUG";
          filePath = "${config.services.traefik.dataDir}/traefik.log";
          format = "json";
        };

        certificatesResolvers = {
          cloudflare = {
            acme = {
              storage = "${config.services.traefik.dataDir}/acme.json";
              dnsChallenge = {
                provider = "cloudflare";
                resolvers = [
                  "1.1.1.1:53"
                  "1.0.0.1:53"
                ];
              };
            };
          };
        };
        api.dashboard = true;
      };
      dynamicConfigOptions = {
        http.middlewares = lib.mkMerge [
          {
            dashboard-auth = {
              basicAuth = {
                usersFile = "${config.sops.secrets.traefik-auth-file.path}";
              };
            };
          }
          cfg.middlewares
        ];
        http.routers = lib.mkMerge [
          (lib.optionalAttrs (cfg.dashboardHost != null) {
            api = {
              rule = "Host(`${cfg.dashboardHost}`)";
              entrypoints = [ "websecure" ];
              middlewares = [ "dashboard-auth" ];
              service = "api@internal";
              tls.certResolver = "cloudflare";
            };
          })
          (lib.mapAttrs (name: routerCfg: {
            rule = routerCfg.rule;
            entrypoints = routerCfg.entrypoints;
            service = routerCfg.service;
            middlewares = routerCfg.middlewares;
          } // lib.optionalAttrs routerCfg.tls {
            tls.certResolver = "cloudflare";
          }) cfg.routers)
        ];
        http.services = lib.mapAttrs (name: serviceCfg: {
          loadBalancer = {
            servers = [
              { url = serviceCfg.url; }
            ];
          };
        }) cfg.services;
      };
    };

    # Open firewall ports for Traefik
    networking.firewall = {
      allowedTCPPorts = [
        80   # HTTP
        443  # HTTPS
      ];
    };
  };
}
