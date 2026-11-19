{
  lib,
  writeCheckedShellApplication,
  nix,
  path,
  runCommand,
  runCommandLocal,
  gnugrep,
  pkgs,
  testers,
  cacert,
}:
let
  # Doesn't support finalAttrs :(
  self = writeCheckedShellApplication {
    name = "nix-about";
    purePath = true;
    text = ''
      set_nixpkgs_args () {
          nixpkgs_args+=(--arg pkgsPath "$1")
      }

      set_flake_args () {
          nixpkgs_args+=(--argstr flake "$1")
      }

      set_system_arg () {
          nixpkgs_args+=(--argstr system "$1")
      }

      packages=()
      nixpkgs_args=()

      while (( $# > 0 )); do
          case "$1" in
          -p|--nixpkgs)
              set_nixpkgs_args "$2"
              shift 2
              ;;
          -p*)
              set_nixpkgs_args "''${1#-p}"
              shift
              ;;
          --nixpkgs=*)
              set_nixpkgs_args "''${1#--nixpkgs=}"
              shift
              ;;

          -f|--flake)
              set_flake_args "$2"
              shift 2
              ;;
          -f*)
              set_flake_args "''${1#-f}"
              shift
              ;;
          --flake=*)
              set_flake_args "''${1#--flake=}"
              shift
              ;;

          -s|--system)
              set_system_arg "$2"
              shift 2
              ;;
          -s*)
              set_system_arg "''${1#-s}"
              shift
              ;;
          --system=*)
              set_system_arg "''${1#--system=}"
              shift
              ;;

          --)
              shift
              packages+=("$@")
              break
              ;;
          *)
              packages+=("$1")
              shift
              ;;
          esac
      done

      if (( "''${#packages[*]}" == 0 )); then
          exit 0
      fi

      first=Yes
      for p in "''${packages[@]}"; do
          if [[ "$first" ]]; then
              package_names='['
              first=
          else
              package_names+=' '
          fi
          # shellcheck disable=SC1003
          escaped_name="''${p//'\'/'\\'}"
          escaped_name="''${escaped_name//${"'"}''${'/'\''${'}"
          escaped_name="''${escaped_name//'"'/'\"'}"
          package_names+="\"$escaped_name\""
      done
      package_names+=']'

      ${nix}/bin/nix \
          --extra-experimental-features 'nix-command flakes' \
          eval \
          --read-only \
          --arg pkgnames "$package_names" \
          "''${nixpkgs_args[@]}" \
          --file ${./about.nix} \
          --raw \
          output
    '';

    passthru.tests =
      let
        pkgs' = pkgs;
        mkTest =
          {
            name,
            cmdArgs ? [ ],
            pkgs ? pkgs',
            pkgPath ? [ "vim" ],
            pkg ? lib.getAttrFromPath pkgPath pkgs,
            pkgName ? pkg.pname,
            pkgVersion ? pkg.version,
            env ? { },
            local ? true,
            ...
          }@args:
          (if local then runCommandLocal else runCommand) "nix-about-${name}"
            (
              {
                __structuredAttrs = true;
                nativeBuildInputs = [
                  self
                  gnugrep
                ];
                env = {
                  NIX_PATH = "nixpkgs=${path}";
                }
                // env;
              }
              // (removeAttrs args [
                "name"
                "cmdArgs"
                "pkgs"
                "pkgPath"
                "pkg"
                "pkgName"
                "pkgVersion"
                "preCheck"
                "env"
              ])
            )
            ''
              # Can't access the store normally when inside the build sandbox.
              export NIX_REMOTE="local?root=$TMPDIR"
              HOME="$(mktemp -d)"
              export HOME
              nix-about \
                  ${lib.escapeShellArgs cmdArgs} \
                  ${lib.escapeShellArg (lib.concatStringsSep "." pkgPath)} \
                  >"$out"
              grep -Fx 'Attribute: '${lib.escapeShellArg (lib.concatStringsSep "." pkgPath)} "$out"
              grep -Fx 'Package: '${lib.escapeShellArg pkgName} "$out"
              grep -Fx 'Version: '${lib.escapeShellArg pkgVersion} "$out"
            '';
      in
      {
        basic = mkTest { name = "basic"; };

        withExplicitDefaultPkgs = mkTest {
          name = "with-explicit-default-packages";
          cmdArgs = [
            "-p"
            "<nixpkgs>"
          ];
        };

        withExplicitPkgsPath = mkTest {
          name = "with-explicit-pkgs-path";
          cmdArgs = [ "--nixpkgs=${path}" ];
        };

        withExplicitDefaultFlake = mkTest {
          name = "with-explicit-default-flake";
          cmdArgs = [ "-fpath:${path}" ];

          # Flakes are slower due to the requirement to copy them to the
          # store, so it can be worth offloading them elsewhere, particularly
          # as there's very little data needed to be copied to/from a remote
          # builder.
          local = false;
        };

        withOldFlake =
          let
            flakeStr = "github:NixOS/nixpkgs?rev=ac62194c3917d5f474c1a844b6fd6da2db95077d";
          in
          testers.invalidateFetcherByDrvHash mkTest {
            name = "with-old-flake";
            cmdArgs = [
              "--flake"
              flakeStr
              # Need to specify system so the hash remains the same regardless of
              # the system running the test.  And since we're doing that, we
              # might as well check cross-system behaviour with a system I'm
              # pretty sure I'm not using.
              "--system"
              "powerpc64le-linux"
            ];
            pkgs = (builtins.getFlake flakeStr).legacyPackages.x86_64-linux;

            # This needs to be a FOD so it can have network access to fetch
            # from GitHub.
            env.NIX_SSL_CERT_FILE = "${cacert}/etc/ssl/certs/ca-bundle.crt";
            outputHash = "sha256-th+jYn83S45PAT7H+mU0W3PfnuebFnhqHsHgpnhLX5w=";

            # Flakes are slower due to the requirement to copy them to the
            # store, so it can be worth offloading them elsewhere, particularly
            # as there's very little data needed to be copied to/from a remote
            # builder.
            local = false;
          };

        withDotAttrs = mkTest {
          name = "with-dot-attrs";
          pkgPath = [
            "python3Packages"
            "requests"
          ];
        };
      };
  };
in
self
