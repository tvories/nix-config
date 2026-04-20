{
  description = "taylor Nix Flake";

  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://cache.garnix.io"
      "https://numtide.cachix.org"
      "https://bjw-s.cachix.org"
      "https://tvories.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
      "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
      "bjw-s.cachix.org-1:dWyzjMYlnKeq01PplRWadakXfZQBoxJN7zGO6/HwsPs="
      "tvories.cachix.org-1:Ql12AwHIbutZhu6fs3Ld29JfKWBZtZvu5araZnwcT+E="
    ];
  };

  inputs = {
    # Nixpkgs and unstable
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # impermanence
    # https://github.com/nix-community/impermanence
    impermanence.url = "github:nix-community/impermanence";

    # nur
    nur.url = "github:nix-community/NUR";

    # nix-community hardware quirks
    # https://github.com/nix-community
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # Home manager
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix-darwin
    nix-darwin = {
      url = "github:LnL7/nix-darwin/nix-darwin-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # For installing homebrew
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";

    mac-app-util.url = "github:hraban/mac-app-util";

    # sops-nix
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # NixVim
    nixvim = {
      url = "github:nix-community/nixvim/nixos-25.11";
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

    # Rust toolchain overlay
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
    };

    # nix-index pre-built database
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      nix-darwin,
      nix-homebrew,
      nixvim,
      nix-vscode-extensions,
      sops-nix,
      nixpkgs-unstable,
      nix-ld-vscode,
      nixoswsl,
      vscode-server,
      nixos-generators,
      disko,
      rust-overlay,
      mac-app-util,
      nixos-hardware,
      ...
    }@inputs:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      overlays = import ./overlays { inherit inputs; };
      mkSystemLib = import ./lib/mkSystem.nix { inherit inputs overlays; };
      flake-packages = self.packages;

      legacyPackages = forAllSystems (
        system:
        import nixpkgs {
          inherit system;
          overlays = builtins.attrValues overlays;
          config.allowUnfree = true;
          allowUnfreePredicate = _: true;
        }
      );
    in
    {
      inherit overlays;

      packages = forAllSystems (

        system:
        let
          pkgs = legacyPackages.${system};
        in
        import ./pkgs {
          inherit pkgs;
          inherit inputs;
        }
      );

      nixosConfigurations = {
        nas-vm = mkSystemLib.mkNixosSystem "x86_64-linux" "nas-vm" flake-packages;
        nas3 = mkSystemLib.mkNixosSystem "x86_64-linux" "nas3" flake-packages;
        wsl = mkSystemLib.mkNixosSystem "x86_64-linux" "wsl" flake-packages;
        tback = mkSystemLib.mkNixosSystem "aarch64-linux" "tback" flake-packages;
        homebox = mkSystemLib.mkNixosSystem "x86_64-linux" "homebox" flake-packages;
        utm-arm = mkSystemLib.mkNixosSystem "aarch64-linux" "utm-arm" flake-packages;
      };

      darwinConfigurations = {
        DVA-YY669XDT42 = mkSystemLib.mkDarwinSystem "aarch64-darwin" "DVA-YY669XDT42" flake-packages;
        DVA-C02CQ7GCMD6T = mkSystemLib.mkDarwinSystem "x86_64-darwin" "DVA-C02CQ7GCMD6T" flake-packages;
      };

      # Convenience output that aggregates the outputs for home, nixos.
      # Also used in ci to build targets generally.
      ciSystems =
        let
          nixos = nixpkgs.lib.genAttrs (builtins.attrNames inputs.self.nixosConfigurations) (
            attr: inputs.self.nixosConfigurations.${attr}.config.system.build.toplevel
          );
          darwin = nixpkgs.lib.genAttrs (builtins.attrNames inputs.self.darwinConfigurations) (
            attr: inputs.self.darwinConfigurations.${attr}.system
          );
        in
        nixos // darwin;

      iso = nixos-generators.nixosGenerate {
        system = "x86_64-linux";
        format = "install-iso";
        modules = [
          sops-nix.nixosModules.sops
          ./hosts/bootstrap/default.nix
        ];
      };
      sd = nixos-generators.nixosGenerate {
        system = "aarch64-linux";
        format = "sd-aarch64";
        modules = [
          sops-nix.nixosModules.sops
          ./hosts/bootstrap/default.nix
        ];
      };
      # aarch64 install ISO with GUI for bootstrapping UTM VMs via nixos-anywhere
      "iso-aarch64" = nixos-generators.nixosGenerate {
        system = "aarch64-linux";
        format = "install-iso";
        modules = [
          sops-nix.nixosModules.sops
          ./hosts/bootstrap/default.nix
          (
            { pkgs, lib, ... }:
            {
              # Override grub device from bootstrap profile (not applicable for ISO)
              boot.loader.grub.devices = lib.mkForce [ "nodev" ];

              # GNOME desktop for the live environment
              services.xserver.enable = true;
              services.displayManager.gdm.enable = true;
              services.desktopManager.gnome.enable = true;

              # Tools needed to run nixos-anywhere from within the live ISO
              environment.systemPackages = with pkgs; [
                nixos-anywhere
                git
                vim
                curl
              ];
            }
          )
        ];
      };
    };
}
