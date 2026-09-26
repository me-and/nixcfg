{
  writeCheckedShellApplication,
  dig,
  coreutils,
}:
writeCheckedShellApplication {
  name = "wait-for-host";
  runtimeInputs = [
    dig.host
    coreutils
  ];
  purePath = true;
  text = ''
    waitforhost () {
        for (( n=0; n<10; n++ )); do
            if host -t A "$1"; then
                return 0
            else
                echo "Cannot find $1, waiting for $(( 2 ** n )) seconds"
                sleep "$(( 2 ** n ))"
            fi
        done
        # Last chance: return code is from this call
        host -t A "$1"
    }

    for host; do
        waitforhost "$host"
    done
  '';
}
