{ config, lib, pkgs, ... }:
let
  cfg = config.programs.nix-about;
  nix-about = pkgs.writeShellApplication {
    name = "nix-about";
    text = ''
      ${config.nix.package}/bin/nix \
          --extra-experimental-features nix-command \
          eval \
          --read-only \
          --argstr pkgname "$1" \
          --file ${(./about.nix)} \
          --raw \
          output
    '';
  };
in {
  options.programs.nix-about = {
    enable = lib.mkEnableOption "Enable nix-about package query.";
    package = lib.mkOption {
      type = lib.types.package;
      default = nix-about;
      description = "nix-about package to use.";
    };
  };

  config.environment.systemPackages = lib.mkIf cfg.enable [ cfg.package ];
}
