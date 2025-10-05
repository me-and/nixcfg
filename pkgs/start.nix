{writeShellApplication}:
writeShellApplication {
  name = "start";
  text = ''
    command_args=()
    convert_paths=YesPlease
    while (( $# > 0 )); do
        case "$1" in
            -P) convert_paths=
                shift
                ;;

            --) command_args+=("$@")
                break
                ;;

            *)  command_args+=("$1")
                shift
                ;;
        esac
    done

    if [[ "$convert_paths" ]]; then
        old_command_args=("''${command_args[@]}")
        command_args=()
        for arg in "''${old_command_args[@]}"; do
            if [[ "$arg" = */* ]]; then
                command_args+=("$(/bin/wslpath -w "$arg")")
            else
                command_args+=("$arg")
            fi
        done
    fi

    # Powershell needs backticks and single quotes escaping, and its escape
    # character is a backtick.
    command_args=("''${command_args[@]//\`/\`\`}")
    command_args=("''${command_args[@]//\'/\`\'}")

    command="''${command_args[*]}"

    powershell.exe -Command "start \"$command\""
  '';
}
