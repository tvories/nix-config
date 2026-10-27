# Placeholder until felix is installed: replace with the output of
# `nixos-generate-config --show-hardware-config` run on the fitlet2.
# Filesystems come from disk-config.nix (disko), so the generated
# fileSystems/swapDevices entries can be dropped.
{
  lib,
  modulesPath,
  ...
}:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "sdhci_pci"
    "mmc_block"
    "usb_storage"
    "usbhid"
    "sd_mod"
  ];
  boot.kernelModules = [ "kvm-intel" ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault true;
}
