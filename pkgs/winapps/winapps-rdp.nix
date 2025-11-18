{
  writeCheckedShellApplication,
  freerdp,
}:
writeCheckedShellApplication {
  name = "winapps-rdp";
  runtimeInputs = [ freerdp ];
  text = ''
    username=
    password=
    ip=
    while read -r line; do
        case "$line" in
        RDP_USER=\"*\")
            username="''${line#RDP_USER=\"}"
            username="''${username%\"}"
            ;;
        RDP_PASS=\"*\")
            password="''${line#RDP_PASS=\"}"
            password="''${password%\"}"
            ;;
        RDP_IP=\"*\")
            ip="''${line#RDP_IP=\"}"
            ip="''${ip%\"}"
            ;;
        esac
    done <"$HOME"/.config/winapps/winapps.conf

    config_error=
    if [[ -z "$username" ]]; then
        echo 'no username found in winapps.conf' >&2
        config_error=Yes
    fi
    if [[ -z "$password" ]]; then
        echo 'no password found in winapps.conf' >&2
        config_error=Yes
    fi
    if [[ -z "$ip" ]]; then
        echo 'no IP address found in winapps.conf' >&2
        config_error=Yes
    fi
    if [[ "$config_error" ]]; then
        exit 78 # EX_CONFIG
    fi

    exec xfreerdp /u:"$username" /p:"$password" /v:"$ip" /cert:tofu
  '';
}
