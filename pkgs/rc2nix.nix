# Because I'd rather not use the plasma-manager instantiated version of nixpkgs
# when I could use my own.
{
  writeShellApplication,
  python3,
  inputs,
}:
writeShellApplication {
  name = "rc2nix";
  runtimeInputs = [ python3 ];
  text = ''python3 ${inputs.plasma-manager}/script/rc2nix.py "$@"'';
}
