{ inputs, overlays, ... }:
{
  mkNixosSystem =
    system: hostname: flake-packages:
    let
      isRpi = system == "aarch64-linux";
    in
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = builtins.attrValues overlays;
        config = {
          allowUnfree = true;
          allowUnfreePredicate = _: true;
        };
      };
      modules = [
        {
          nixpkgs.hostPlatform = system;
          _module.args = {
            inherit inputs flake-packages;
          };
        }
        inputs.home-manager.nixosModules.home-manager
        inputs.sops-nix.nixosModules.sops
        inputs.disko.nixosModules.disko
        (if isRpi then inputs.nixos-hardware.nixosModules.raspberry-pi-4 else { })
        {
          home-manager = {
            useUserPackages = true;
            useGlobalPkgs = true;
            sharedModules = [
              inputs.sops-nix.homeManagerModules.sops
              inputs.catppuccin.homeManagerModules.catppuccin
            ];
            extraSpecialArgs = {
              inherit inputs hostname flake-packages;
            };
            users.taylor = ../. + "/homes/taylor";
            backupFileExtension = "hm-backup";
          };
        }
        ../hosts/_modules/common
        ../hosts/_modules/nixos
        ../hosts/${hostname}
      ];
      specialArgs = {
        inherit inputs hostname;
      };
    };

  mkDarwinSystem =
    system: hostname: flake-packages:
    inputs.nix-darwin.lib.darwinSystem {
      inherit system;
      pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = builtins.attrValues overlays;
        config = {
          allowUnfree = true;
          allowUnfreePredicate = _: true;
        };
      };
      modules = [
        {
          nixpkgs.hostPlatform = system;
          _module.args = {
            inherit inputs flake-packages;
          };
        }
        inputs.home-manager.darwinModules.home-manager
        inputs.mac-app-util.darwinModules.default
        {
          home-manager = {
            useUserPackages = true;
            useGlobalPkgs = true;
            sharedModules = [
              inputs.mac-app-util.homeManagerModules.default
              inputs.sops-nix.homeManagerModules.sops
              inputs.nixvim.homeManagerModules.nixvim
              inputs.catppuccin.homeManagerModules.catppuccin
            ];
            extraSpecialArgs = {
              inherit inputs hostname flake-packages;
            };
            users.tvories = ../. + "/homes/taylor";
          };
        }
        ../hosts/_modules/common
        ../hosts/_modules/darwin
        ../hosts/${hostname}
      ];
      specialArgs = {
        inherit inputs hostname;
      };
    };
}
