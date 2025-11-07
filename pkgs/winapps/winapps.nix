{ inputs, callPackage }:
callPackage "${inputs.winapps}/packages/winapps" { inherit (inputs.winapps.inputs) nix-filter; }
