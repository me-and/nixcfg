{writeShellApplication}:
writeShellApplication {
  name = "start";
  text = ''
    command="$*"

    # Powershell needs backticks and single quotes escaping, and its escape
    # character is a backtick.
    command="''${command//\`/\`\`}"
    command="''${command//\'/\`\'}"

    powershell.exe -Command "start '$command'"
  '';
}
