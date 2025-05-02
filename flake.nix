{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    private.url = "github:me-and/nixcfg-private";
    winapps = {
      url = "github:winapps-org/winapps";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    nixos-hardware,
    nixos-wsl,
    home-manager,
    private,
    winapps,
  }: let
    inherit (nixpkgs.lib.attrsets) mapAttrs mapAttrs' nameValuePair optionalAttrs;
    inherit (nixpkgs.lib.lists) optional optionals;
    inherit (nixpkgs.lib.strings) removeSuffix;

    subdirfiles = (import ./lib/subdirfiles.nix) nixpkgs.lib;

    boxen = {
      hex = {
        system = "x86_64-linux";
        me = "adam";
        winapps = true;
        nixosExtraModules = [nixos-hardware.nixosModules.framework-16-7040-amd];
      };

      lucy = {
        system = "aarch64-linux";
        me = "adam";
        nixosExtraModules = [nixos-hardware.nixosModules.raspberry-pi-4];
      };
    };
  in {
    nixosConfigurations =
      mapAttrs (
        name: {
          system,
          wsl ? false,
          winapps ? false,
          includeHomeManager ? true,
          includePrivate ? true,
          nixosExtraModules ? [],
          ...
        }:
          nixpkgs.lib.nixosSystem {
            inherit system;
            specialArgs = optionalAttrs winapps {
              winapps-pkgs = winapps.packages."${system}";
            };
            modules = let
              allModules = source: [
                (source.nixosModules.default or {})
                (source.nixosModules."${name}" or {})
              ];
            in
              nixosExtraModules
              ++ allModules self
              ++ optional includeHomeManager home-manager.nixosModules.default
              ++ optional wsl nixos-wsl.nixosModules.default
              ++ optionals includePrivate (allModules private);
          }
      )
      boxen;

    homeConfigurations =
      mapAttrs' (
        name: {
          system,
          me,
          includePrivate ? true,
          hmExtraModules ? [],
          ...
        }:
          nameValuePair "${me}@${name}"
          (
            home-manager.lib.homeManagerConfiguration {
              pkgs = nixpkgs.legacyPackages."${system}";
              modules = let
                allModules = source: [
                  (source.hmModules.default or {})
                  (source.hmModules."${me}" or {})
                  (source.hmModules."${name}" or {})
                  (source.hmModules."${me}@${name}" or {})
                ];
              in
                hmExtraModules
                ++ allModules self
                ++ optionals includePrivate (allModules private);
            }
          )
      )
      boxen;

    nixosModules =
      {
        default.imports = [
          ./common
          ./modules/nixos
          ./modules/shared
          ./nixos/common
        ];
      }
      // mapAttrs (name: value: import value) (subdirfiles ./nixos "configuration.nix");

    hmModules =
      {
        default.imports = [
          ./common
          ./modules/home-manager
          ./modules/shared
          ./home-manager/common
        ];
      }
      // mapAttrs (name: value: import value) (subdirfiles ./home-manager "home.nix");

    overlays = let
      overlayPaths = builtins.readDir ./overlays;
    in
      mapAttrs' (
        name: value:
          nameValuePair
          (removeSuffix ".nix" name)
          (import (./overlays + "/${name}"))
      )
      overlayPaths;
  };
}
