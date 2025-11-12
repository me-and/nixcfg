{
  inputs,
  writeCheckedShellApplication,
  gnused,
  podman-compose,
}:
writeCheckedShellApplication {
  name = "winapps-init";
  runtimeInputs = [
    gnused
    podman-compose
  ];
  text = ''
    password=

    while (( $# > 0 )); do
        case "$1" in
        -p)
            password="$2"
            shift 2
            ;;
        -p*)
            password="''${2#-p}"
            shift
            ;;
        *)
            echo "unexpected argument $1" >&2
            exit 64 # EX_USAGE
            ;;
        esac
    done

    if [[ ! "$password" ]]; then
        echo 'no password specified' >&2
        exit 64 # EX_USAGE
    fi

    config_dir="$HOME"/.config/winapps
    mkdir -p "$config_dir"
    cp ${inputs.winapps}/compose.yaml "$config_dir"/compose.yaml
    cp ${./winapps.conf} "$config_dir"/winapps.conf
    chmod 600 "$config_dir"/compose.yaml "$config_dir"/winapps.conf
    sed -i 's/PASSWORD: "MyWindowsPassword"/PASSWORD: "'"$password"'"/' "$config_dir"/compose.yaml
    sed -i 's/RDP_PASS="MyWindowsPassword"/RDP_PASS="'"$password"'"/' "$config_dir"/winapps.conf

    podman-compose --file "$config_dir"/compose.yaml up
  '';
}
