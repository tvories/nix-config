{ config, pkgs, lib, ... }:
{
  # This is required so that pod can reach the API server (running on port 6443 by default)
  networking.firewall.allowedTCPPorts = [ 6443 ];

  services.k3s = {
    enable = true;
    role = "server";
    package = pkgs.unstable.k3s;
  };

  services.k3s.extraFlags = toString [
    "--tls-san" "nas.mcbadass.local"
    "--disable" "local-storage"
    "--disable" "traefik"
    # "--flannel-iface=vlan80"
    # "--node-ip=${toString (builtins.elemAt config.networking.interfaces.vlan80.ipv4.addresses 0).address}"
    # "--node-external-ip=${toString (builtins.elemAt config.networking.interfaces.vlan80.ipv4.addresses 0).address}"
    "--flannel-backend=vxlan"
    "--disable-network-policy"
  ];

  networking.firewall.trustedInterfaces = [ "tunl0" "cni0" "flannel.1" ];

  environment.systemPackages = [ pkgs.unstable.k3s ];
}
