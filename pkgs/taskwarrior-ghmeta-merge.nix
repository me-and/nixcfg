{ writeCheckedShellApplication, jq }:
writeCheckedShellApplication {
  name = "taskwarrior-ghmeta-merge";
  runtimeInputs = [ jq ];
  text = ''
    task "$@" export |
        jq '(map(.ghmeta | fromjson) | flatten(1) | unique | tojson) as $json | map(.ghmeta = $json)' |
        task import
  '';
}
