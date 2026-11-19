{
  writeCheckedShellApplication,
  nix,
}:
writeCheckedShellApplication {
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
}
