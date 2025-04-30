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
    inherit (nixpkgs.lib.attrsets) mapAttrs mapAttrs' nameValuePair;
    inherit (nixpkgs.lib.strings) removeSuffix;

    boxen = {
      hex = {
        system = "x86_64-linux";
        me = "adam";
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
        name: attrs:
          nixpkgs.lib.nixosSystem {
            inherit (attrs) system;
            specialArgs = {
              winapps-pkgs = winapps.packages."${attrs.system}";
            };
            modules =
              [
                nixos-wsl.nixosModules.default
                home-manager.nixosModules.default
                (./. + "/nixos/${name}/configuration.nix")
                (private.nixosModules.default or {})
                (private.nixosModules."${name}" or {})
              ]
              ++ (attrs.nixosExtraModules or []);
          }
      )
      boxen;

    homeConfigurations =
      mapAttrs' (
        name: attrs:
          nameValuePair "${attrs.me}@${name}"
          (
            home-manager.lib.homeManagerConfiguration {
              pkgs = nixpkgs.legacyPackages."${attrs.system}";
              modules = [
                (./. + "/home-manager/${name}/home.nix")
                (private.hmModules.default or {})
                (private.hmModules."${attrs.me}@${name}" or {})
              ];
            }
          )
      )
      boxen;

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
