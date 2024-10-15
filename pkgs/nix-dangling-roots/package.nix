# Find Nix garbage collection roots that:
# - Aren't in one of the standard garbage-collected locations for Home Manager
#   or NixOS generations.
# - Aren't broken symlinks that will get cleaned up next time the Nix garbage
#   collector runs.
{
  writeCheckedShellApplication,
  findutils,
  coreutils,
}:
writeCheckedShellApplication {
  name = "nix-dangling-roots";
  purePath = true;
  text = ''
    exec ${findutils}/bin/find \
        /nix/var/nix/gcroots/auto \
        -type l \
        \! -xtype l \
        \! -lname '/home/*/.local/state/nix/profiles/*' \
        \! -lname '/home/*/.local/state/home-manager/gcroots/*' \
        \! -lname '/nix/var/nix/profiles/*' \
        -exec \
            ${coreutils}/bin/ls --color=auto -lvh {} +
  '';
}
