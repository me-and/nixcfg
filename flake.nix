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
    wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    private = {
      url = "github:me-and/nixcfg-private";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    user-systemd-config = {
      url = "github:me-and/user-systemd-config";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      nixos-hardware,
      home-manager,
      winapps,
      wsl,
      private,
      user-systemd-config,
    }@inputs:
    let
      inherit (nixpkgs.lib.attrsets)
        mapAttrs
        mapAttrs'
        nameValuePair
        optionalAttrs
        ;
      inherit (nixpkgs.lib.lists) optional optionals;
      inherit (nixpkgs.lib.strings) removeSuffix;

      boxen = {
        hex = {
          system = "x86_64-linux";
          me = "adam";
        };

        lucy = {
          system = "aarch64-linux";
          me = "adam";
        };
      };
    in
    {
      nixosConfigurations = mapAttrs (
        name:
        {
          system,
          me,
          includePersonal ? true,
          ...
        }:
        nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs;
          };
          modules =
            let
              allModules = source: [
                (source.nixosModules.default or { })
                (source.nixosModules."${name}" or { })
                (optionalAttrs includePersonal (source.nixosModules.personal or { }))
              ];
            in
            [
              {
                users.me = me;
                networking.hostName = name;
              }
              home-manager.nixosModules.default
            ]
            ++ allModules self
            ++ allModules private;
        }
      ) boxen;

      homeConfigurations = mapAttrs' (
        name:
        {
          system,
          me,
          includePersonal ? true,
          ...
        }:
        nameValuePair "${me}@${name}" (
          home-manager.lib.homeManagerConfiguration {
            pkgs = import nixpkgs {
              inherit system;
              overlays = builtins.attrValues self.overlays;
              config = import ./config.nix;
            };
            extraSpecialArgs = {
              inherit inputs;
            };
            modules =
              let
                # TODO Looks like some things included in this list might
                # get evaluated twice, which is *mostly* fine unless there
                # are multiple config options that get added to a
                # configured list.
                allModules = source: [
                  (source.hmModules.default or { })
                  (source.hmModules."${me}" or { })
                  (source.hmModules."${name}" or { })
                  (source.hmModules."${me}@${name}" or { })
                  (optionalAttrs includePersonal (source.hmModules.personal or { }))
                ];
              in
              [
                {
                  home.username = me;
                  home.hostName = name;
                }
              ]
              ++ allModules self
              ++ allModules private;
          }
        )
      ) boxen;

      nixosModules =
        let
          default = {
            imports = builtins.attrValues (
              self.lib.dirfiles {
                dir = ./nixos/common;
              }
            );

            nixpkgs.config = import ./config.nix;
            nixpkgs.overlays = builtins.attrValues self.overlays;
          };
          systemModules = mapAttrs (n: v: import v) (
            self.lib.subdirfiles {
              dir = ./nixos;
              filename = "configuration.nix";
            }
          );
          optionalModules = mapAttrs (n: v: import v) (self.lib.dirfiles { dir = ./modules/nixos; });
        in
        self.lib.unionOfDisjointAttrsList [
          { inherit default; }
          systemModules
          optionalModules
        ];

      hmModules =
        let
          # Don't need to specify overlay or nixpkgs configuration here, as
          # that's given in the arguments to the homeManagerConfiguration
          # function.
          default = {
            imports = builtins.attrValues (
              self.lib.dirfiles {
                dir = ./home-manager/common;
              }
            );
          };
          systemModules = mapAttrs (n: v: import v) (
            self.lib.subdirfiles {
              dir = ./home-manager;
              filename = "home.nix";
            }
          );
          optionalModules = mapAttrs (n: v: import v) (self.lib.dirfiles { dir = ./modules/home-manager; });
        in
        self.lib.unionOfDisjointAttrsList [
          { inherit default; }
          systemModules
          optionalModules
        ];

      overlays = builtins.mapAttrs (n: v: import v) (self.lib.dirfiles { dir = ./overlays; });

      lib = import ./lib.nix { inherit (nixpkgs) lib; };
    }
    // flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = builtins.attrValues self.overlays;
        };
        lib = pkgs.lib;
      in
      {
        legacyPackages = import ./. { inherit pkgs; };
        packages = lib.filterAttrs (n: v: lib.isDerivation v) self.legacyPackages."${system}";

        formatter = pkgs.nixfmt-tree;
      }
    );
}
