{ inputs, outputs, config, ... }: {
# Time
  networking.timeServers = ["192.168.1.1"];
  services.chrony = {
    enable = true;
  };
}