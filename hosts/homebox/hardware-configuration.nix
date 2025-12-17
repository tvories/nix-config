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
    # kernelPackages = pkgs.linuxKernel.packages.linux_rpi4;
    initrd.kernelModules = [ ];
    initrd.availableKernelModules = [
      "xhci_pci"
      "ahci"
      "mpt3sas"
      "nvme"
      "usbhid"
      "usb_storage"
      "sd_mod"
      "sr_mod"
    ];
    # supportedFilesystems = [ "xfs" ];
    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];
    loader = {
      efi = {
        canTouchEfiVariables = true;
      };
      grub = {
        enable = true;
        efiSupport = true;
        devices = [ "nodev" ];
      };
    };
  };

  # boot.initrd.supportedFilesystems = [ "zfs" ];
  # boot.supportedFilesystems = [ "zfs" ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # boot.loader.raspberryPi = {
  #   enable = true;
  #   version = 3;
  #   firmwareConfig = ''
  #     core_freq=250
  #   '';
  # };

  # Use the extlinux boot loader. (NixOS wants to enable GRUB by default)
  # Enables the generation of /boot/extlinux/extlinux.conf
  # boot.loader.generic-extlinux-compatible.enable = true;

  # fileSystems."/" = {
  #   device = "/dev/disk/by-uuid/44444444-4444-4444-8888-888888888888";
  #   fsType = "ext4";
  #   options = [ "noatime" ];
  # };

  # fileSystems."/boot" = {
  #   device = "/dev/disk/by-label/boot";
  #   fsType = "vfat";
  # };

  # swapDevices = [ ];

  # powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
