{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    home-manager = {
      # My fork, adding
      #
      # https://github.com/nix-community/home-manager/pull/7476
      # https://github.com/nix-community/home-manager/pull/7618
      url = "github:me-and/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    winapps = {
      url = "github:winapps-org/winapps";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    private = {
      url = "github:me-and/nixcfg-private";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    nixos-hardware,
    home-manager,
    winapps,
    private,
  } @ flake: let
    inherit (nixpkgs.lib.attrsets) mapAttrs mapAttrs' nameValuePair optionalAttrs;
    inherit (nixpkgs.lib.lists) optional optionals;
    inherit (nixpkgs.lib.strings) removeSuffix;

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
    };
  in
    {
      nixosConfigurations =
        mapAttrs (
          name: {
            system,
            me,
            includeWinapps ? false,
            includePersonal ? true,
            nixosExtraModules ? [],
            ...
          }:
            nixpkgs.lib.nixosSystem {
              inherit system;
              specialArgs =
                {
                  inherit flake;
                }
                // optionalAttrs includeWinapps {
                  winapps-pkgs = winapps.packages."${system}";
                };
              modules = let
                allModules = source: [
                  (source.nixosModules.default or {})
                  (source.nixosModules."${name}" or {})
                  (optionalAttrs includePersonal (source.nixosModules.personal or {}))
                ];
              in
                [
                  {
                    users.me = me;
                    networking.hostName = name;
                  }
                  home-manager.nixosModules.default
                ]
                ++ nixosExtraModules
                ++ allModules self
                ++ allModules private;
            }
        )
        boxen;

      homeConfigurations =
        mapAttrs' (
          name: {
            system,
            me,
            includePersonal ? true,
            hmExtraModules ? [],
            ...
          }:
            nameValuePair "${me}@${name}"
            (
              home-manager.lib.homeManagerConfiguration {
                pkgs = nixpkgs.legacyPackages."${system}";
                extraSpecialArgs = {
                  inherit flake;
                };
                modules = let
                  # TODO Looks like some things included in this list might
                  # get evaluated twice, which is *mostly* fine unless there
                  # are multiple config options that get added to a
                  # configured list.
                  allModules = source: [
                    (source.hmModules.default or {})
                    (source.hmModules."${me}" or {})
                    (source.hmModules."${name}" or {})
                    (source.hmModules."${me}@${name}" or {})
                    (optionalAttrs includePersonal (source.hmModules.personal or {}))
                  ];
                in
                  [
                    {
                      home.username = me;
                      home.hostName = name;
                    }
                  ]
                  ++ hmExtraModules
                  ++ allModules self
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
        // mapAttrs (name: value: import value) (self.lib.subdirfiles {
          dir = ./nixos;
          filename = "configuration.nix";
        });

      hmModules =
        {
          default.imports = [
            ./common
            ./modules/home-manager
            ./modules/shared
            ./home-manager/common
          ];
        }
        // mapAttrs (name: value: import value) (self.lib.subdirfiles {
          dir = ./home-manager;
          filename = "home.nix";
        });

      overlays =
        builtins.mapAttrs
        (n: v: import v)
        (self.lib.dirfiles {dir = ./overlays;});

      lib = import ./lib.nix {inherit (nixpkgs) lib;};
    }
    // flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          overlays = builtins.attrValues self.overlays;
        };
        lib = pkgs.lib;
      in {
        legacyPackages = import ./. {inherit pkgs;};
        packages = lib.filterAttrs (n: v: lib.isDerivation v) self.legacyPackages."${system}";
      }
    );
}
