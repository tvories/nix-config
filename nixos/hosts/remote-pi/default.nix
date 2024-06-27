{ config, pkgs, lib, ... }: {
  imports = [
    # Host-specific
      ./hardware-configuration.nix
      ./wireguard.nix
      ./restic-server.nix
      
      # Common imports
      ../common/nixos
      ../common/nixos/users/taylor
      ../common/nixos/users/tadmin
      ../common/nixos/users/service_accounts
      ../common/optional/fish.nix
      # ../common/optional/k3s-server.nix
      # ../common/optional/nfs-server.nix
      # ../common/optional/samba-server.nix
      # ../common/optional/zfs.nix
      # ../common/optional/monitoring.nix
      # ../common/optional/smartd.nix
      ../common/optional/chrony.nix
  ];
  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID2+7PUnROyy7dALYGxsQSN16hz4iblHXtFJ6dHCUIBW"
  ];

  networking = {
    hostName = "tback";
    domain = "mcbadass.local";
    dhcpcd.enable = true;
  };

  sops.age.keyFile = "/var/lib/sops-nix/key.txt";
  
  # Group config
  users.groups = {
    backup-rw = {
      gid = 65541;
      members = ["taylor"];
    };
    docs-rw = {
      gid = 65543;
      members = ["taylor"];
    };
    media-rw = {
      gid = 65539;
      members = ["taylor"];
    };
  };

  environment.systemPackages = [
    pkgs.cryptsetup
    pkgs.usbutils
    pkgs.restic-rest-server
  ];

  virtualisation.docker.enable = true;

  users.extraGroups.docker.members = [
      "taylor"
    ];

  # Autofs auto mount luks
  services.autofs = {
    enable = true;
    autoMaster = ''
      /backup /etc/auto.luks --timeout=600
    '';
    debug = true;
  };

  sops.secrets.sda1-key = {
    sopsFile = ./secret.sops.yaml;
  };

  environment.etc = {
    # Creates auto.luks file
    "auto.luks" = {
      text = ''
        #!/run/current-system/sw/bin/bash
        device=$1
        device_crypt=''${device}_autocrypt

        mountopts="-fstype=ext4,defaults,noatime,nodiratime"

        # map the LUKS device, if not already done
        /run/current-system/sw/bin/cryptsetup luksOpen /dev/''${device} ''${device_crypt} -d=/etc/.keys/''${device}.key 2>/dev/null

        echo $mountopts :/dev/mapper/''${device_crypt}
      '';
      mode = "0755";
    };
    ".keys/sda1.key" = {
      source = config.sops.secrets.sda1-key.path;
      mode = "0400";
    };
  };


  services.prometheus.exporters = {
    node = {
      enable = true;
      enabledCollectors = [
        "diskstats"
        "filesystem"
        "loadavg"
        "meminfo"
        "netdev"
        "stat"
        "time"
        "uname"
        "systemd"
      ];
    };
    smartctl = {
      enable = true;
    };
  };

  sops.secrets.tback-password = {
    sopsFile = ./secret.sops.yaml;
    neededForUsers = true;
  };

  # Backup user account
  users.users.tback = {
    isNormalUser = true;
    shell = pkgs.fish;
    hashedPasswordFile = config.sops.secrets.tback-password.path;
    extraGroups = [
      "backup-rw"
    ];

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID6CloskNbqtcgAasuLxYwlAsVheXcZm1Jt37xpzmlda 1pw-backup-key"
    ];
  };

  # may fix issues with network service failing during a nixos-rebuild
  systemd.services.NetworkManager-wait-online.enable = lib.mkForce false;
  systemd.services.systemd-networkd-wait-online.enable = lib.mkForce false;

  nixpkgs.config.permittedInsecurePackages = [
    "vault-1.14.10"
  ];
  
  system.stateVersion = "24.05";
  # nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}