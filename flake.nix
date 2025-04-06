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
  };

  outputs = {
    self,
    nixpkgs,
    nixos-hardware,
    nixos-wsl,
    home-manager,
    private,
  }: let
    inherit (nixpkgs.lib.attrsets) mapAttrs mapAttrs' nameValuePair;

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
  };
}
