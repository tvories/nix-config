{ ... }:
{
  imports = [
    ./nix.nix
    ./sops.nix
    ./users.nix
    ./filesystems
    ./services
    ./packages.nix
  ];

  documentation.nixos.enable = false;

  # Increase open file limit for sudoers
  security.pam.loginLimits = [
    {
      domain = "@wheel";
      item = "nofile";
      type = "soft";
      value = "524288";
    }
    {
      domain = "@wheel";
      item = "nofile";
      type = "hard";
      value = "1048576";
    }
  ];

  modules = {
    services = {
      chrony = {
        enable = true;
      };
      msmtp.enable = true;
    };
  };
  networking.timeServers = [
    "192.168.1.1"
    "us.pool.ntp.org"
  ];

  system = {
    stateVersion = "24.11";
  };
}
