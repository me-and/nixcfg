{
  runCommand,
  python3,
}:
runCommand "select-by-weight" { buildInputs = [ python3 ]; } ''
  mkdir -p "$out"/bin
  cp ${./select-by-weight.py} "$out"/bin/select-by-weight
  patchShebangs "$out"/bin/select-by-weight
''
