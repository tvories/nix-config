{
  description = "taylor Nix Flake";

  inputs = {
    # Nixpkgs and unstable
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # Home manager
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix-darwin
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # sops-nix
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # NixVim
    nixvim = {
      url = "github:nix-community/nixvim/nixos-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # VSCode community extensions
    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # for VSCode remote-ssh
    nix-ld-vscode = {
      url = "github:scottstephens/nix-ld-vscode/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixoswsl = {
      url = "github:nix-community/NixOS-WSL/main";
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

    # Catppuccin
    catppuccin = {
      url = "github:catppuccin/nix/v1.0.1";
    };

    # Nix Inspect
    nix-inspect = {
      url = "github:bluskript/nix-inspect";
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    nix-darwin,
    nix-inspect,
    nixvim,
    nix-vscode-extensions,
    sops-nix,
    nixpkgs-unstable,
    nix-ld-vscode,
    nixoswsl,
    vscode-server,
    nixos-generators,
    disko,
    ... } @inputs:
    let
      supportedSystems = ["x86_64-linux" "aarch64-darwin" "aarch64-linux"];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      overlays = import ./overlays { inherit inputs; };
      mkSystemLib = import ./lib/mkSystem.nix {inherit inputs overlays;};
      flake-packages = self.packages;

      legacyPackages = forAllSystems (
        system:
          import nixpkgs {
            inherit system;
            overlays = builtins.attrValues overlays;
            config.allowUnfree = true;
          }
      );
      # inherit (self) outputs;
    in
    {
      inherit overlays;

      packages = forAllSystems (
        system: let
          pkgs = legacyPackages.${system};
        in
          import ./pkgs {
            inherit pkgs;
            inherit inputs;
          }
      );

    nixosConfigurations = {
      # nas3 = mkSystemLib.mkNixosSystem "x86_64-linux" "nas3" flake-packages;
      # tback = mkSystemLib.mkNixosSystem "x86_64-linux" "tback" flake-packages;
      nas-vm = mkSystemLib.mkNixosSystem "x86_64-linux" "nas-vm" flake-packages;
      wsl = mkSystemLib.mkNixosSystem "x86_64-linux" "wsl" flake-packages;
    };

    darwinConfigurations = {
      DVA-YY669XDT42 = mkSystemLib.mkDarwinSystem "aarch64-darwin" "DVA-YY669XDT42" flake-packages;
    };

    # Convenience output that aggregates the outputs for home, nixos.
    # Also used in ci to build targets generally.
    ciSystems =
      let
        nixos = nixpkgs.lib.genAttrs
          (builtins.attrNames inputs.self.nixosConfigurations)
          (attr: inputs.self.nixosConfigurations.${attr}.config.system.build.toplevel);
        darwin = nixpkgs.lib.genAttrs
          (builtins.attrNames inputs.self.darwinConfigurations)
          (attr: inputs.self.darwinConfigurations.${attr}.system);
      in
        nixos // darwin;
    };
      # TODO: Old Config
      # mkNixos = modules: nixpkgs.lib.nixosSystem {
      #   inherit modules;
      #   specialArgs = { inherit inputs outputs; };
      # };
    
    # TODO: Old config
    # in
    # {
    #   packages.x86_64-linux = {
    #     bootstrap = nixos-generators.nixosGenerate {
    #       system = "x86_64-linux";
    #       format = "install-iso";
    #       modules = [
    #         sops-nix.nixosModules.sops
    #         # { disko.devices.disk.disk1.device = "/dev/sda" }
    #         ./nixos/hosts/bootstrap/configuration.nix
    #       ];
    #       # formatConfigs.virtualbox = {config, ...}: {
    #       #   services.openssh.enable = true;
    #       # }
    #     };
    #   };

    # TODO: old config
    #   packages.aarch64-linux = {
    #     bootstrap = nixos-generators.nixosGenerate {
    #       system = "aarch64-linux";
    #       format = "sd-aarch64";
    #       modules = [
    #         sops-nix.nixosModules.sops
    #         ./nixos/hosts/bootstrap/configuration.nix
    #       ];
    #     };
    #   };

    #   # Custom packages and modifications, exported as overlays
    #   overlays = import ./nixos/overlays { inherit inputs; };

    #   nixosConfigurations = {
    #     # Metal
    #     "nas" = mkNixos [disko.nixosModules.disko ./nixos/hosts/nas];
        
    #     # VMs
    #     "nas-vm" = mkNixos [disko.nixosModules.disko ./nixos/hosts/nas-vm];

    #     # WSL
    #     "wsl" = mkNixos [./nixos/hosts/wsl];

    #     # Remote Pi
    #     "remote-pi" = mkNixos [./nixos/hosts/remote-pi];
    #   };
    # };
}
