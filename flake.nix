{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/04ef94c4c158";

  outputs = {nixpkgs, ...}: {
    nixosConfigurations.lucy = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [./configuration.nix];
    };
  };
}
