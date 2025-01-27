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
      sopsFile = ./secret.sops.yaml
    };
    sops.secrets.cf-token = {
      sopsFile = ./secret.sops.yaml
    };

    systemd.services.traefik.environment = {
      CF_API_EMAIL_FILE = "${config.sops.secrets.cf-email.path}";
      CF_API_TOKEN_FILE = "${config.sops.secrets.cf-token.path}";
    };

    services.traefik = {
      enable = true;
      sops.secrets.
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
            http.tls.certResolver = "cloudflare";
            domains = [
              {
                main = "t-vo.us";
                sans = ["*.t-vo.us"];
              }
            ];
          };
        };
        certificateResolvers = {
          cloudflare = {
            acme = {
              email = "tvories@gmail.com"
              storage = "${config.services.traefik.dataDir}/acme.json";
              dnsChallenge = {
                provider = "cloudflare";
                resolvers = [ "1.1.1.1:53" "1.0.0.1:53" ];
              };
            }
          };
        };
      };
    };
  };
}
