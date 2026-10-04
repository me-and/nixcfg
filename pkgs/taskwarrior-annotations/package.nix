{
  writeCheckedShellApplication,
  jq,
}:
writeCheckedShellApplication {
  name = "taskwarrior-annotations";
  runtimeInputs = [ jq ];
  text = ''
    # Use the `jq` `NO_COLOR` environment variable to control colour output, as
    # that's the same variable that would be used for `jq`'s own normal output
    # colour handling.  Provide plain-text output if stdout isn't a terminal.
    #
    # TODO Better control / overriding of this value.
    if [[ ! -t 1 ]]; then
        export NO_COLOR=
    fi
    task "$@" export | jq --raw-output --from-file ${./script.jq}
  '';
}
