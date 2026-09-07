{
  writeCheckedShellApplication,
  jq,
}:
writeCheckedShellApplication {
  name = "taskwarrior-annotations";
  runtimeInputs = [ jq ];
  text = ''
    task "$@" export | jq --raw-output --from-file ${./script.jq}
  '';
}
