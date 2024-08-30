{
  writeCheckedShellApplication,
  nix,
}:
writeCheckedShellApplication {
  name = "nix-about";
  text = ''
    set_nixpkgs_args () {
        nixpkgs_args+=(--arg pkgs "import ($1) {}")
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
        --extra-experimental-features nix-command \
        eval \
        --read-only \
        --arg pkgnames "$package_names" \
        "''${nixpkgs_args[@]}" \
        --file ${./about.nix} \
        --raw \
        output
  '';
}
