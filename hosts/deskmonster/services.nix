# Services moved here from the old Windows/WSL Docker setup: the GPU voice
# containers for Home Assistant, and the restic REST server on the F: drive.
{
  lib,
  config,
  ...
}:
{
  # GPU voice containers (whisper, kokoro, whisper.cpp). Their compose file
  # stays in k8s-gitops (cluster-0 home/gpu-deployment) beside the manifests
  # it mirrors, and runs with `docker compose up -d`; its restart policy
  # brings it back after reboots. It requests the GPU through CDI, so this
  # generates the CDI spec in /var/run/cdi and turns on Docker's CDI support.
  hardware.nvidia-container-toolkit.enable = true;

  # LAN only, like the RDP rule in default.nix. Home Assistant and the
  # cluster connect from 192.168.80.x node IPs, and OPNsense's HAProxy
  # health-checks from the LAN.
  networking.firewall.extraCommands = ''
    iptables -A nixos-fw -p tcp -s 192.168.0.0/16 --dport 10300 -j nixos-fw-accept  # wyoming whisper
    iptables -A nixos-fw -p tcp -s 192.168.0.0/16 --dport 10200 -j nixos-fw-accept  # wyoming kokoro bridge
    iptables -A nixos-fw -p tcp -s 192.168.0.0/16 --dport 8178  -j nixos-fw-accept  # whisper.cpp (BookBridge)
    iptables -A nixos-fw -p tcp -s 192.168.0.0/16 --dport 8000  -j nixos-fw-accept  # restic rest-server
  '';

  # The old Windows F: drive (HGST 6 TB), which holds the restic repos under
  # /restic. Windows still dual-boots and uses it, so it stays NTFS. Owned by
  # taylor with the restic group, so both can write.
  fileSystems."/mnt/f" = {
    device = "/dev/disk/by-uuid/58B0E9BAB0E99EAE";
    fsType = "ntfs3";
    options = [
      "uid=${toString config.users.users.taylor.uid}"
      "gid=${toString config.ids.uids.restic}"
      "umask=007"
      # Refuse filenames Windows can't open.
      "windows_names"
      # Don't hold up boot if Windows left the volume hibernated or dirty.
      "nofail"
      "x-systemd.device-timeout=15s"
    ];
  };

  # The built-in module rather than modules.services.restic-server (tback's):
  # it's socket-activated and sandboxed.
  services.restic.server = {
    enable = true;
    dataDir = "/mnt/f/restic";
    # Port only: socket activation listens on every address.
    listenAddress = "8000";
    htpasswd-file = config.sops.secrets.restic-server-htpasswd.path;
    # Same cert as the old server: nas3 pins it with --cacert.
    extraFlags = [
      "--tls"
      "--tls-cert"
      config.sops.secrets.restic-public-cert.path
      "--tls-key"
      config.sops.secrets.restic-private-key.path
    ];
  };
  # If the disk didn't mount, don't write into the bare mountpoint on the root
  # filesystem, and don't let user activation create /mnt/f/restic there.
  systemd.services.restic-rest-server.unitConfig.RequiresMountsFor = [ "/mnt/f/restic" ];
  users.users.restic.createHome = lib.mkForce false;

  # Owned by restic: the service sandbox can still read them under
  # ProtectSystem=strict, but runs as restic.
  sops.secrets = lib.genAttrs [ "restic-server-htpasswd" "restic-public-cert" "restic-private-key" ] (_: {
    sopsFile = ./secret.sops.yaml;
    owner = "restic";
  });
}
