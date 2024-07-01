{ config, ... }: {

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
      ips = [ "10.0.55.7/24"];
      listenPort = 51820;
      privateKeyFile = config.sops.secrets.wg-private-key.path;
      
      peers = [
        {
          publicKey = "a6Z4poPL/ew8AyMhj05JAgwQW+5Unsp4feGhrIalzkQ=";
          allowedIPs = ["0.0.0.0/0"];
          # endpoint = "${config.sops.templates.wg-endpoint.path}";
          endpoint = "vpn.t-vo.us:51820";
          persistentKeepalive = 25;
        }
      ];
    };
  };
}