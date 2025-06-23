{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    winapps = {
      url = "github:winapps-org/winapps";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    private.url = "github:me-and/nixcfg-private";
    workCfg = {
      url = "git+ssh://git@git.datcon.co.uk/add/adinwoodie-nixcfg.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    nixos-hardware,
    nixos-wsl,
    home-manager,
    winapps,
    private,
    workCfg,
  } @ flakeInputs: let
    inherit (nixpkgs.lib.attrsets) mapAttrs mapAttrs' nameValuePair optionalAttrs;
    inherit (nixpkgs.lib.lists) optional optionals;
    inherit (nixpkgs.lib.strings) removeSuffix;

    subdirfiles = (import ./lib/subdirfiles.nix) nixpkgs.lib;

    boxen = {
      hex = {
        system = "x86_64-linux";
        me = "adam";
        includeWinapps = true;
        nixosExtraModules = [nixos-hardware.nixosModules.framework-16-7040-amd];
      };

      lucy = {
        system = "aarch64-linux";
        me = "adam";
        nixosExtraModules = [nixos-hardware.nixosModules.raspberry-pi-4];
      };

      desktop-4d6hh84-nixos = {
        system = "x86_64-linux";
        me = "adamdinwoodie";
        work = true;
        wsl = true;
        winUsername = "AdamDinwoodie";
        includePersonal = false;
      };
    };
  in
    {
      nixosConfigurations =
        mapAttrs (
          name: {
            system,
            me,
            wsl ? false,
            winUsername ? null,
            includeWinapps ? false,
            work ? false,
            includeHomeManager ? true,
            includePersonal ? true,
            nixosExtraModules ? [],
            ...
          }:
            assert nixpkgs.lib.assertMsg ((winUsername != null) -> wsl) "Windows username cannot be set if wsl is not true";
              nixpkgs.lib.nixosSystem {
                inherit system;
                specialArgs = optionalAttrs includeWinapps {
                  inherit flakeInputs;
                  winapps-pkgs = winapps.packages."${system}";
                };
                modules = let
                  allModules = source: [
                    (source.nixosModules.default or {})
                    (source.nixosModules."${name}" or {})
                    (optionalAttrs includePersonal (source.nixosModules.personal or {}))
                  ];

                  windowsConfig = {
                    imports = [
                      nixos-wsl.nixosModules.default
                      ./extraModules/nixos/wsl.nix
                    ];
                    wsl.defaultUser = me;
                    wsl.enable = true;
                  };
                in
                  [
                    {
                      users.me = me;
                      networking.hostName = name;
                    }
                  ]
                  ++ nixosExtraModules
                  ++ allModules self
                  ++ optional includeHomeManager home-manager.nixosModules.default
                  ++ optional wsl windowsConfig
                  ++ optionals work (allModules workCfg)
                  ++ allModules private;
              }
        )
        boxen;

      homeConfigurations =
        mapAttrs' (
          name: {
            system,
            me,
            wsl ? false,
            winUsername ? null,
            work ? false,
            includePersonal ? true,
            hmExtraModules ? [],
            ...
          }:
            assert nixpkgs.lib.assertMsg ((winUsername != null) -> wsl) "Windows username cannot be set if wsl is not true";
              nameValuePair "${me}@${name}"
              (
                home-manager.lib.homeManagerConfiguration {
                  pkgs = nixpkgs.legacyPackages."${system}";
                  extraSpecialArgs = {
                    inherit flakeInputs;
                  };
                  modules = let
                    allModules = source: [
                      (source.hmModules.default or {})
                      (source.hmModules."${me}" or {})
                      (source.hmModules."${name}" or {})
                      (source.hmModules."${me}@${name}" or {})
                      (optionalAttrs includePersonal (source.hmModules.personal or {}))
                    ];

                    windowsConfig = {
                      home.wsl.enable = true;
                      home.wsl.windowsUsername = nixpkgs.lib.mkIf (winUsername != null) winUsername;
                    };
                  in
                    [
                      {
                        home.username = me;
                        home.hostName = name;
                      }
                    ]
                    ++ hmExtraModules
                    ++ allModules self
                    ++ optional wsl windowsConfig
                    ++ optionals work (allModules workCfg)
                    ++ allModules private;
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
    }
    // flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          overlays = builtins.attrValues self.overlays;
        };
      in {packages = import ./pkgs {inherit pkgs;};}
    );
}
