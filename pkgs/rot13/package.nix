{
  coreutils,
  writeShellApplication,
}:
writeShellApplication {
  name = "rot13";
  text = "exec ${coreutils}/bin/tr '[A-Za-z]' '[N-ZA-Mn-za-m]'";
}
