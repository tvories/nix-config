{ config, pkgs, lib, home-manager, ... }: {

  imports = [ ];

  networking.firewall = {
    allowedUDPPorts = [ 51820 ];
  };

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