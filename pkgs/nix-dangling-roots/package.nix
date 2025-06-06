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
    exclude_args=(
        \! -lname '/home/*/.cache/nix/flake-registry.json'
        \! -lname '/home/*/.local/state/home-manager/gcroots/*'
        \! -lname '/home/*/.local/state/nix/profiles/*'
        \! -lname '/nix/var/nix/profiles/*'
        \! -lname '/root/.cache/nix/flake-registry.json'
        \! -lname '/root/.local/state/home-manager/gcroots/*'
        \! -lname '/root/.local/state/nix/profiles/*'
    )
    ls_cmd=(ls --color=auto -lhU)
    mode='ls'

    while (( $# > 0 )); do
        case "$1" in
            -a) exclude_args=()
                shift
                ;;

            -l)
                # Want user to be able to use backslashes in their ls command
                # string.
                # shellcheck disable=2162
                read -a ls_cmd <<<"$2"
                shift 2
                ;;

            -t) mode=target
                shift
                ;;
            -T) mode=target0
                shift
                ;;

            -l*)
                # Flag that takes an argument: separate and reparse
                set -- "-''${1: 1:1}" "''${1: 2}" "''${@: 2}"
                ;;
            -a*|-t*|-T*)
                # Flag that takes no arguments: separate and reparse.
                set -- "-''${1: 1:1}" "-''${1: 2}" "''${@: 2}"
                ;;

            *)  printf 'unrecognised argument %s\n' "$1" >&2
                exit 64 # EX_USAGE
                ;;
        esac
    done

    find_roots () {
        local printf="$1"
        shift
        find /nix/var/nix/gcroots/auto -type l \! -xtype l \( "''${exclude_args[@]}" \) -printf "$printf"
    }

    case "$mode" in
        ls) find_roots '%l\t%p\0' |
                sort -zV |
                cut -f2- -z |
                xargs -r0 "''${ls_cmd[@]}"
            ;;

        target)
            find_roots '%l\n'
            ;;

        target0)
            find_roots '%l\0'
            ;;

        *)
            printf 'unexpected mode %s\n' "$mode" >&2
            exit 70 # EX_SOFTWARE
            ;;
    esac
  '';
}
