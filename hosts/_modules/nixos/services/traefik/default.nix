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
                  main = "t-vo.us";
                  sans = [
                    "*.t-vo.us"
                    "tback.t-vo.us"
                  ];
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
              # email = "***";
              storage = "${config.services.traefik.dataDir}/acme.json";
              dnsChallenge = {
                provider = "cloudflare";
                resolvers = [ "1.1.1.1:53" "1.0.0.1:53" ];
              };
            };
          };
        };
        api.dashboard = true;
        # api.insecure = true;
      };
      dynamicConfigOptions = {
        http.middlewares = {
          dashboard-auth = {
            basicAuth = {
              usersFile = "${config.sops.secrets.traefik-auth-file.path}";
            };
          };
        };
        http.routers = {
          api = {
            rule = "Host(`tback.t-vo.us`)";
            entrypoints = ["websecure"];
            middlewares = ["dashboard-auth"];
            service = "api@internal";
            tls.certResolver = "cloudflare";
          };
        };
      };
    };
  };
}
