{
  config,
  pkgs,
  ...
}:

let
  # Define the IP address to test connectivity to
  testIP = "10.0.55.1";
  # Define the service name
  wireguardService = "wireguard-wg0.service";

  # Script to test connectivity and restart the WireGuard service if it fails
  connectivityCheckScript = pkgs.writeShellScriptBin "connectivity-check" ''
    set -euo pipefail

    # Test connectivity to the IP address
    if ! ${pkgs.iputils}/bin/ping -c 1 -W 5 ${testIP} > /dev/null 2>&1; then
      echo "Connectivity to ${testIP} failed. Restarting ${wireguardService}..."
      systemctl restart ${wireguardService}
    else
      echo "Connectivity to ${testIP} is OK."
    fi
  '';
in

{

  imports = [ ];

  # networking.useNetworkd = true;

  sops.secrets.wg-private-key = {
    sopsFile = ./secret.sops.yaml;
    mode = "0400";
  };

  sops.secrets.wg-endpoint = {
    sopsFile = ./secret.sops.yaml;
  };
  # sops.templates."wg-endpoint".content = ''
  #   password = "${config.sops.secrets.wg-endpoint}"
  # '';

  # boot.extraModulePackages = [config.boot.kernelPackages.wireguard];
  # systemd.network = {
  #   enable = true;
  #   netdevs = {
  #     "10-wg0" = {
  #       netdevConfig = {
  #         Kind = "wireguard";
  #         Name = "wg0";
  #         MTUBytes = 1420;
  #       };
  #       wireguardConfig = {
  #         PrivateKeyFile = config.sops.secrets.wg-private-key.path;
  #         ListenPort = 51820;
  #       };
  #       wireguardPeers = [
  #         {
  #           PublicKey = "a6Z4poPL/ew8AyMhj05JAgwQW+5Unsp4feGhrIalzkQ=";
  #           AllowedIPs = [ "0.0.0.0/0" ];
  #           Endpoint = "vpn.t-vo.us:51820";
  #         }
  #       ];
  #     };
  #   };
  #   networks.wg0 = {
  #     matchConfig.Name = "wg0";
  #     address = [ "10.0.55.7/24"];
  #     DHCP = "no";
  #     dns = ["192.168.1.240"];
  #   };
  # };

  networking.wireguard.interfaces = {
    wg0 = {
      ips = [ "10.0.55.7/24" ];
      listenPort = 51820;
      privateKeyFile = config.sops.secrets.wg-private-key.path;

      peers = [
        {
          publicKey = "a6Z4poPL/ew8AyMhj05JAgwQW+5Unsp4feGhrIalzkQ=";
          allowedIPs = [
            "192.168.0.0/16"
            "10.0.55.0/24"
          ];
          # endpoint = "${config.sops.templates.wg-endpoint.path}";
          endpoint = "vpn.t-vo.us:51820";
          persistentKeepalive = 25;
        }
      ];
    };
  };
  systemd.timers.wg-connectivity-check-timer = {
    description = "Run the connectivity check every 5 minutes";
    timerConfig = {
      OnCalendar = "*:0/5"; # Run every 5 minutes
      Persistent = true;
      Unit = "wg-connectivity-check.service";
    };
    wantedBy = [ "timers.target" ];
    partOf = [ "wg-connectivity-check.service" ];
  };
  # Create a systemd service to run the connectivity check periodically
  systemd.services.wg-connectivity-check = {
    description = "Check connectivity to ${testIP} and restart ${wireguardService} if it fails";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "simple";
      ExecStart = "${connectivityCheckScript}/bin/connectivity-check";
      # Restart = "on-failure";
      # RestartSec = "5m"; # Retry every 5 minutes
    };
  };
}
