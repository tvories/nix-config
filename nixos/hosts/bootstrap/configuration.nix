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

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
