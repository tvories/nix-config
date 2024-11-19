{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];
  boot = {
    initrd.kernelModules = [ ];
    initrd.availableKernelModules = [
      "xhci_pci"
      "usbhid"
    ];
    kernelModules = [ ];
    extraModulePackages = [ ];
    loader = {
      grub.enable = false;
      # Enables the generation of /boot/extlinux/extlinux.conf
      generic-extlinux-compatible.enable = true;
      timeout = 2;
    };
  };

  # boot.initrd.supportedFilesystems = [ "zfs" ];
  # boot.supportedFilesystems = [ "zfs" ];

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";

  # boot.loader.raspberryPi = {
  #   enable = true;
  #   version = 4;
  # };

  # Use the extlinux boot loader. (NixOS wants to enable GRUB by default)
  # Enables the generation of /boot/extlinux/extlinux.conf
  # boot.loader.generic-extlinux-compatible.enable = true;

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/44444444-4444-4444-8888-888888888888";
    fsType = "ext4";
  };

  swapDevices = [ ];

  # powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";
}
