{ inputs, pkgs, ... }:
{
  imports = [
    inputs.vscode-server.nixosModules.default
    inputs.nixoswsl.nixosModules.wsl
    # Host-specific hardware
    ./hardware-configuration.nix

    #     # Common imports
    # ../common/nixos
    #     ../common/nixos/users/taylor
    # ../common/nixos/users/tadmin
    # ../common/optional/fish.nix
    #     ../common/optional/k3s-server.nix
    #     ../common/optional/nfs-server.nix
    #     # ../common/optional/virtualbox.nix
    #     ../common/optional/samba-server.nix
    #     ../common/optional/zfs.nix
    #     ../common/optional/monitoring.nix

    #     # Secrets

  ];

  config = {
    networking = {
      hostName = "deskmonster";
    };
    boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

    wsl = {
      enable = true;
      interop.register = true;
      defaultUser = "taylor";
      extraBin = with pkgs; [
        { src = "${coreutils}/bin/uname"; }
        { src = "${coreutils}/bin/dirname"; }
        { src = "${coreutils}/bin/readlink"; }
      ];
    };
    programs.nix-ld.enable = true;
    services.vscode-server.enable = true;
    system.stateVersion = "24.05";
    sops.age.keyFile = "/home/taylor/.config/sops/age/keys.txt";

    # Tadmin user
    users.users.taylor = {
      isNormalUser = true;
      shell = pkgs.fish;
      # packages = [ pkgs.home-manager ];
    };

    environment.systemPackages = [
      pkgs.powershell
      pkgs.sops
    ];
  };
}
