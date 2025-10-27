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
      inputs.personalCfg.follows = "";
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
        filterAttrs
        mapAttrs
        mapAttrs'
        nameValuePair
        optionalAttrs
        ;
      inherit (flake-utils.lib) flattenTree eachSystem;
      inherit (self.lib) dirmodules unionOfDisjointAttrsList;

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

      makeNixpkgs =
        system:
        import nixpkgs {
          inherit system;
          overlays = builtins.attrValues self.overlays ++ builtins.attrValues private.overlays;
          config = import ./config.nix;
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
                nixpkgs.config = import ./config.nix;
                nixpkgs.overlays = builtins.attrValues self.overlays ++ builtins.attrValues private.overlays;
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
            pkgs = makeNixpkgs system;
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
                  (source.homeModules.default or { })
                  (source.homeModules."${me}" or { })
                  (source.homeModules."${name}" or { })
                  (source.homeModules."${me}@${name}" or { })
                  (optionalAttrs includePersonal (source.homeModules.personal or { }))
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

      nixosModules = dirmodules { dir = ./nixos; };

      homeModules = dirmodules { dir = ./home-manager; };

      overlays = builtins.mapAttrs (n: v: import v) (self.lib.dirfiles { dir = ./overlays; });

      lib = import ./lib.nix { inherit (nixpkgs) lib; };
    }
    // eachSystem [ "x86_64-linux" "aarch64-linux" ] (
      system:
      let
        pkgs = makeNixpkgs system;
      in
      {
        legacyPackages = import ./. {
          inherit pkgs;
          inherit (pkgs) lib;
          mylib = self.lib;
        };
        packages = flattenTree self.legacyPackages."${system}";

        checks =
          let
            checkableNixosImages = filterAttrs (n: v: v.pkgs.system == system) self.nixosConfigurations;
            checkableHomeImages = filterAttrs (n: v: v.pkgs.system == system) self.homeConfigurations;
          in
          unionOfDisjointAttrsList [
            self.packages."${system}"
            (mapAttrs (n: v: v.config.system.build.toplevel) checkableNixosImages)
            (mapAttrs (n: v: v.activationPackage) checkableHomeImages)
          ];

        formatter = pkgs.nixfmt-tree;
      }
    );
}
