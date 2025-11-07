{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    home-manager = {
      url = "github:nix-community/home-manager";
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
      inherit (builtins)
        attrValues
        concatMap
        functionArgs
        intersectAttrs
        mapAttrs
        removeAttrs
        ;
      inherit (nixpkgs.lib) nixosSystem;
      inherit (nixpkgs.lib.attrsets)
        filterAttrs
        mapAttrs'
        nameValuePair
        optionalAttrs
        unionOfDisjoint
        ;
      inherit (flake-utils.lib) flattenTree eachSystem;
      inherit (home-manager.lib) homeManagerConfiguration;
      inherit (self.lib) dirfiles dirmodules unionOfDisjointAttrsList;

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
          overlays = concatMap attrValues [
            self.overlays
            private.overlays
          ];
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
        nixosSystem {
          specialArgs = {
            inherit nixos-hardware winapps wsl;
            personalCfg = self;
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
                nixpkgs.overlays = concatMap attrValues [
                  self.overlays
                  private.overlays
                ];
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
        nameValuePair "${me}@${name}" (homeManagerConfiguration {
          pkgs = makeNixpkgs system;
          extraSpecialArgs = {
            inherit user-systemd-config;
            personalCfg = self;
          };
          modules =
            let
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
        })
      ) boxen;

      nixosModules = dirmodules { dir = ./nixos; };

      homeModules = dirmodules { dir = ./home-manager; };

      overlays =
        let
          overlayFiles = dirfiles { dir = ./overlays; };

          # I want to be able to pass flake inputs to my overlays, but I also
          # want to be able to use normal overlays as-is.  To permit that,
          # inspect the overlays to see if they take an attrset as their
          # intiial argument, and if so pass it the relevant parts of the flake
          # input.
          inputArgs = unionOfDisjoint { inherit inputs; } inputs;
          closeOverlay =
            fn:
            let
              args = functionArgs fn;
            in
            if args == { } then fn else fn (intersectAttrs args inputArgs);
        in
        mapAttrs (n: v: closeOverlay (import v)) overlayFiles;

      lib = import ./lib { inherit (nixpkgs) lib; };
    }
    // eachSystem [ "x86_64-linux" "aarch64-linux" ] (
      system:
      let
        pkgs = makeNixpkgs system;
      in
      {
        legacyPackages = import ./pkgs {
          inherit pkgs inputs;
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
            (removeAttrs self.packages."${system}" [ "everything" ])
            (mapAttrs (n: v: v.config.system.build.toplevel) checkableNixosImages)
            (mapAttrs (n: v: v.activationPackage) checkableHomeImages)
          ];

        formatter = pkgs.nixfmt-tree;
      }
    );
}
