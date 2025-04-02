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
  runtimeInputs = [findutils coreutils];
  text = ''
    if (( $# == 1 )) && [[ "$1" = -a ]]; then
        exclude_args=()
    elif (( $# == 0 )); then
        exclude_args=(
            \! -lname '/home/*/.local/state/nix/profiles/*'
            \! -lname '/root/.local/state/nix/profiles/*'
            \! -lname '/home/*/.local/state/home-manager/gcroots/*'
            \! -lname '/root/.local/state/home-manager/gcroots/*'
            \! -lname '/nix/var/nix/profiles/*'
        )
    else
        echo 'unrecognised arguments' >&2
        exit 64 # EX_USAGE
    fi

    find /nix/var/nix/gcroots/auto -type l \! -xtype l "''${exclude_args[@]}" -printf '%l\t%p\0' |
        sort -zV |
        cut -f2- -z |
        xargs -0 ls --color=auto -lhU
  '';
}
