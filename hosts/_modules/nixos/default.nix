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
  documentation.man.generateCaches = false; # Speeds up build time. Man caches take forever to build: https://discourse.nixos.org/t/slow-build-at-building-man-cache/52365

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
