{
  config,
  pkgs,
  lib,
  ...
}:

{
  # Uptime Kuma monitoring service
  config = {
    services.uptime-kuma = {
      enable = true;
      settings = {
        PORT = "3001";
      };
    };

    # Traefik configuration for uptime-kuma
    modules.services.traefik.routers.uptime-kuma = {
      rule = "Host(`uptime-kuma.t-vo.us`)";
      service = "uptime-kuma";
    };

    modules.services.traefik.services.uptime-kuma = {
      url = "http://localhost:3001";
    };
  };
}
