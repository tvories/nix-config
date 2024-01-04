{
  description = "taylor Nix Flake";

  inputs = {
    # Nixpkgs and unstable
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # Home manager
    home-manager = {
      url = "github:nix-community/home-manager/release-23.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # sops-nix
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # for VSCode remote-ssh
    nix-ld-vscode = {
      url = "github:scottstephens/nix-ld-vscode/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixoswsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    vscode-server = {
      url = "github:nix-community/nixos-vscode-server";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # disko for formatting disks
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    sops-nix,
    nixpkgs-unstable,
    nix-ld-vscode,
    nixoswsl,
    vscode-server,
    nixos-generators,
    disko,
    ... }@inputs:
    let
      inherit (self) outputs;
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
      ];

      mkNixos = modules: nixpkgs.lib.nixosSystem {
        inherit modules;
        specialArgs = { inherit inputs outputs; };
      };
    in
    {
      packages.x86_64-linux = {
        bootstrap = nixos-generators.nixosGenerate {
          system = "x86_64-linux";
          format = "install-iso";
          modules = [
            sops-nix.nixosModules.sops
            # { disko.devices.disk.disk1.device = "/dev/sda" }
            ./nixos/hosts/bootstrap/configuration.nix
          ];
          # formatConfigs.virtualbox = {config, ...}: {
          #   services.openssh.enable = true;
          # }
        };
      };

      # Custom packages and modifications, exported as overlays
      overlays = import ./nixos/overlays { inherit inputs; };

      nixosConfigurations = {
        # Metal
        "nas" = mkNixos [disko.nixosModules.disko ./nixos/hosts/nas];
        
        # VMs
        "nas-vm" = mkNixos [disko.nixosModules.disko ./nixos/hosts/nas-vm];

        # WSL
        "wsl" = mkNixos [./nixos/hosts/wsl];
      };
    };
}
