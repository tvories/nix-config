# This configuration lets me use an iso file to bring up a system with an ssh key
#

{ config, pkgs, lib, home-manager, sops-nix, ... }:

{
  imports = [  ];

  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
    devices = [ "/dev/sda" ];
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID2+7PUnROyy7dALYGxsQSN16hz4iblHXtFJ6dHCUIBW"
  ];

  users.users.root.initialHashedPassword = lib.mkDefault "$y$j9T$EK87qu3hpgXBaikeMCV.t1$By.6pQ.stIgheZVJPIM/apdqw3uZAZhyz9CDbxxFeg5";


  services.openssh.enable = true;

  networking = {
    hostName = "nix-bootstrap";
    dhcpcd.enable = true;
  };

  # may fix issues with network service failing during a nixos-rebuild
  systemd.services.NetworkManager-wait-online.enable = lib.mkForce false;
  systemd.services.systemd-networkd-wait-online.enable = lib.mkForce false;

  system.stateVersion = "24.05";
}
