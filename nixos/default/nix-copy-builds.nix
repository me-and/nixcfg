{
  lib,
  mylib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.nix.copyBuilds;
in
{
  options.nix.copyBuilds = {
    copyAllBuilds = lib.mkEnableOption "copying all builds automatically.";

    substituteOnDestination = lib.mkOption {
      description = "Whether to use the `--substitute-on-destination` argument to `nix copy`.";
      type = lib.types.bool;
      default = true;
    };

    destinations = lib.mkOption {
      description = "Remote Nix stores to copy any builds to.";
      type = lib.types.listOf lib.types.singleLineStr; # TODO tighten this
      default = [ ];
    };
  };

  config = lib.mkIf (cfg.destinations != [ ]) {
    nix.settings.post-build-hook = lib.mkIf cfg.copyAllBuilds "${pkgs.mypkgs.nix-copy-builds}/bin/nix-copy-build-hook";

    systemd.services.nix-copy-builds = {
      description = "Copy Nix builds and derivations to remote stores";
      serviceConfig.ExecStart = mylib.escapeSystemdExecArgs (
        [ "${pkgs.mypkgs.nix-copy-builds}/bin/nix-copy-from-build" ]
        ++ lib.optional cfg.substituteOnDestination "--substitute-on-destination"
        ++ cfg.destinations
      );
    };
    systemd.paths.nix-copy-builds = {
      description = "Copy Nix builds and derivations to remote stores";
      pathConfig = {
        DirectoryNotEmpty = "/tmp/nix-copy-post-build-hook";
        MakeDirectory = true;
      };
      wantedBy = [
        "default.target"
        "nix-daemon.service"
      ];
      before = [ "nix-daemon.service" ];
    };
  };
}
