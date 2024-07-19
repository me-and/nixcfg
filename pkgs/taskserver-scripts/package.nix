{
  nettools,
  gnutls,
  openssl,
  coreutils,
  lib,
  writeCheckedShellApplication,
  symlinkJoin,
}: let
  script = name: runtimeInputs:
    writeCheckedShellApplication {
      inherit name runtimeInputs;
      bashOptions = ["errexit" "nounset" "pipefail" "noclobber"];
      purePath = true;
      text = builtins.readFile (lib.path.append ./. name);
    };
in
  symlinkJoin {
    name = "taskserver-scripts";
    paths = [
      (script "taskd-generate-ca-cert" [nettools gnutls coreutils])
      (script "taskd-generate-user-cert" [gnutls coreutils])
      (script "taskd-refresh-ca-cert" [gnutls coreutils openssl])
      (script "taskd-refresh-user-cert" [gnutls coreutils openssl])
    ];
  }
