# Provide both ansi2txt and ansi2html, but using the more powerful ansi2html
# from the ansi2html package.
{
  runCommand,
  colorized-logs,
  ansi2html,
}:
runCommand "ansi2" { } ''
  mkdir -p "$out"/bin
  ln -s ${colorized-logs}/bin/ansi2txt "$out"/bin/
  ln -s ${ansi2html}/bin/ansi2html "$out"/bin/
''
