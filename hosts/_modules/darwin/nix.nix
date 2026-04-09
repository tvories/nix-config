{ ... }:
{
  # GC settings are in common/nix.nix

  # Local aarch64-linux builder VM via Apple Virtualization framework.
  # Fixes cross-building NixOS aarch64-linux hosts from aarch64-darwin.
  nix.linux-builder = {
    enable = true;
    ephemeral = true;
    maxJobs = 4;
    config = {
      virtualisation.darwin-builder = {
        diskSize = 20 * 1024; # 20 GiB
        memorySize = 4 * 1024; # 4 GiB
      };
    };
  };
}
