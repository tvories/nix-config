{
  description = "taylor Nix Flake";

  inputs = {
    # Nixpkgs and unstable
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # Home manager
    home-manager = {
      url = "github:nix-community/home-manager/release-23.05";
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
  };

  outputs = { self, nixpkgs, home-manager, sops-nix, nixpkgs-unstable, nix-ld-vscode, nixoswsl, vscode-server, ... }@inputs:
    let
      inherit (self) outputs;
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        # "aarch64-darwin"
      ];

      mkNixos = modules: nixpkgs.lib.nixosSystem {
        inherit modules;
        specialArgs = { inherit inputs outputs; };
      };
    in
    {
      # Custom packages and modifications, exported as overlays
      overlays = import ./overlays { inherit inputs; };

      nixosConfigurations = {
        # Metal
        "nas" = mkNixos [./hosts/nas];
        # VMs
        "nas-vm" = mkNixos [./hosts/nas-vm];
        # WSL
        "wsl" = mkNixos [
          ./hosts/wsl
          vscode-server.nixosModules.default
          nixoswsl.nixosModules.wsl
          ];
      };
    };
}
