{lib, ...}: let
  commonConfig = {
    services.openssh.enable = lib.mkDefault true;
  };

  keyIfExtant = type: let
    filename = "ssh_host_${type}_key";
    keySourcePath = lib.path.append ../../secrets filename;
    pubkeySourcePath = lib.path.append ../../secrets "${filename}.pub";
  in
    lib.mkIf (builtins.pathExists keySourcePath) {
      assertions = [
        {
          assertion = builtins.pathExists pubkeySourcePath;
          message = "Secrets directory contains private ${type} key but no corresponding public key.";
        }
      ];

      environment.etc."ssh/${filename}" = {
        source = builtins.toString keySourcePath;
        mode = "0600";
      };
      environment.etc."ssh/${filename}.pub" = {
        source = builtins.toString pubkeySourcePath;
        mode = "0644";
      };
    };
in
  lib.mkMerge [
    commonConfig
    (keyIfExtant "rsa")
    (keyIfExtant "ed25519")
  ]
