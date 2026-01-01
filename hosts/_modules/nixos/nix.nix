_: {
  # Limit number of boot entries to prevent /boot from filling up
  boot.loader.grub.configurationLimit = 10;
  boot.loader.systemd-boot.configurationLimit = 10;

  nix.gc = {
    dates = "weekly";
  };
}
