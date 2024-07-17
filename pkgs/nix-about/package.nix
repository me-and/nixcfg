{
  writeShellApplication,
  nix,
}:
writeShellApplication {
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
        *)
            packages+=("$1")
            shift
            ;;
        esac
    done

    first=Yes
    for p in "''${packages[@]}"; do
        if [[ "$first" ]]; then
            first=
        else
            echo
        fi
        ${nix}/bin/nix \
            --extra-experimental-features nix-command \
            eval \
            --read-only \
            --argstr pkgname "$p" \
            "''${nixpkgs_args[@]}" \
            --file ${./about.nix} \
            --raw \
            output
    done
  '';
}
