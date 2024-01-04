{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [];
  
  # ! Local virtualbox config
  boot.initrd.availableKernelModules = [ "ata_piix" "ohci_pci" "ehci_pci" "ahci" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];
  
  boot.loader = {
    efi = {
      canTouchEfiVariables = true;
    };
    grub = {
      enable = true;
      efiSupport = true;
      devices = [ "nodev" ];
    };
  };

  # services.openssh.enable = true;

  environment.systemPackages = map lib.lowPrio [
    pkgs.curl
    pkgs.gitMinimal
  ];

  # Disk config is set in nixos-anywhere disko
  # fileSystems."/" =
  #   { device = "/dev/disk/by-uuid/7be85be4-643b-4bd2-ae94-e960f0b1b334";
  #     fsType = "ext4";
  #   };

  # fileSystems."/boot" =
  #   { device = "/dev/disk/by-uuid/C385-86BC";
  #     fsType = "vfat";
  #   };

  # swapDevices = [ ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  # networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp0s1.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  virtualisation.virtualbox.guest.enable = true;
  # virtualisation.vmware.guest.enable = true;
}
