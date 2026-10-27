# Temporary: tools for unlocking/flashing an Echo Dot 2nd gen ("biscuit") with
# the amonet-biscuit scripts. Remove the import from default.nix once done.
#
#   cd ~/amonet-biscuit-v1.1.0   # the extracted release zip
#   amonet                       # FHS shell with /bin/bash, python3, glibc
#   ./brick.sh / ./bootrom-step.sh / ./fastboot-step.sh   (no sudo)
#
# Needs real x86_64 USB: the exploit ships a prebuilt x86_64 bin/fastboot and
# the BootROM handshake is too timing-sensitive for WSL's usbipd passthrough.
{
  lib,
  pkgs,
  ...
}:
let
  amonet = pkgs.buildFHSEnv {
    name = "amonet";
    targetPkgs =
      p: with p; [
        bash
        coreutils
        gnugrep
        gnused
        findutils
        procps
        unzip
        dos2unix
        usbutils
        android-tools
        (python3.withPackages (ps: [ ps.pyserial ]))
        # Runtime libraries the prebuilt fastboot may link against
        zlib
        libusb1
      ];
    profile = ''
      export PS1="(amonet) \w \$ "
    '';
    runScript = "bash";
  };
in
{
  environment.systemPackages = [
    amonet
    pkgs.android-tools
  ];

  # NetworkManager pulls in ModemManager, which grabs /dev/ttyACM* as soon as
  # the MediaTek BootROM enumerates and breaks the handshake.
  networking.modemmanager.enable = lib.mkForce false;

  # sudo doesn't work inside the FHS shell (bubblewrap sets no_new_privs), so
  # the device nodes have to be usable by dialout members directly.
  services.udev.extraRules = ''
    # MediaTek BootROM / preloader (bootrom-step.sh, boot-recovery.sh)
    SUBSYSTEM=="usb", ATTR{idVendor}=="0e8d", MODE="0660", GROUP="dialout", ENV{ID_MM_DEVICE_IGNORE}="1"
    SUBSYSTEM=="tty", ATTRS{idVendor}=="0e8d", MODE="0660", GROUP="dialout", ENV{ID_MM_DEVICE_IGNORE}="1"
    # Amazon/Lab126: stock and unlocked fastboot, TWRP adb, FireOS adb
    SUBSYSTEM=="usb", ATTR{idVendor}=="1949", MODE="0660", GROUP="dialout"
    # Generic Google fastboot/adb IDs some Amazon builds report
    SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", MODE="0660", GROUP="dialout"
  '';

  users.users.taylor.extraGroups = [ "dialout" ];
}
