#!@runtimeShell@
shopt -s extglob

builders_args=()
use_copy_hook=
max_jobs=
overlays=()
reset_builders=
reset_substituters=
substituters=()
while (( $# > 0 )); do
    case "$1" in
        --builder)
            builders_args+=("$2")
            shift 2
            ;;
        --copy-hook)
            use_copy_hook=YesPlease
            shift
            ;;
        --max-jobs)
            max_jobs="$2"
            shift 2
            ;;
        --overlay)
            overlays+=("$2")
            shift 2
            ;;
        --reset-builders)
            reset_builders=YesPlease
            shift
            ;;
        --reset-substituters)
            reset_substituters=YesPlease
            shift
            ;;
        --substituter)
            substituters+=("$2")
            shift 2
            ;;

        # Reparse options that take arguments.
        --@(builder|max-jobs|overlay|substituter)=*)
            set -- "${1%%=*}" "${1#*=}" "${@: 2}"
            ;;

        # `--` marks the end of options.
        --)
            shift
            break
            ;;

        # Unrecognised option.
        -*)
            exit 64
            ;;

        # First thing that doesn't look like an option marks the start of
        # positional parameters.
        *)
            break
            ;;
    esac
done

extend_nix_config () {
    local option="$1" value="$2"

    NIX_CONFIG="${NIX_CONFIG:+"$NIX_CONFIG"$'\n'}$option = $value"
    export NIX_CONFIG
}

compile_overlays () {
    local overlay

    COMPILED_OVERLAYS='['
    for overlay; do
        COMPILED_OVERLAYS="$COMPILED_OVERLAYS ($overlay)"
    done
    COMPILED_OVERLAYS="$COMPILED_OVERLAYS ]"
}

if [[ "$use_copy_hook" ]]; then
    extend_nix_config post-build-hook @POST-BUILD-HOOK@
fi

if [[ "$reset_substituters" ]]; then
    extend_nix_config substituters "${substituters[*]}"
elif (( ${#substituters[*]} > 0 )); then
    extend_nix_config extra-substituters "${substituters[*]}"
fi

if [[ "$max_jobs" ]]; then
    extend_nix_config max-jobs "$max_jobs"
fi

builders_str=
for builder in "${builders_args[@]}"; do
    case "$builder" in
        hex)
            builders_str="${builders_str:+"$builders_str; "}ssh-ng://nix-ssh@hex.dinwoodie.org x86_64-linux,i686-linux - 4 1 nixos-test,kvm,benchmark,big-parallel,uid-range"
            ;;
        marvin)
            builders_str="${builders_str:+"$builders_str; "}ssh-ng://nix-ssh@marvin.dinwoodie.org x86_64-linux,i686-linux - 4 0.9 nixos-test,kvm,benchmark,big-parallel,uid-range"
            ;;
        miki)
            builders_str="${builders_str:+"$builders_str; "}ssh-ng://nix-ssh@miki.dinwoodie.org x86_64-linux,i686-linux - 4 0.9 nixos-test,kvm,benchmark,big-parallel,uid-range"
            ;;
        jarvis)
            builders_str="${builders_str:+"$builders_str; "}ssh-ng://nix-ssh@jarvis.dinwoodie.org aarch64-linux - 2 0.5 nixos-test,uid-range"
            ;;
        nixbuild.net)
            builders_str="${builders_str:+"$builders_str; "}ssh-ng://eu.nixbuild.net x86_64-linux - 1000 10 nixos-test,kvm,benchmark,big-parallel; ssh-ng://eu.nixbuild.net aarch64-linux - 1000 10 nixos-test,benchmark,big-parallel"
            ;;
        *)
            builders_str="${builders_str:+"$builders_str; "}$builder"
            ;;
    esac
done

if [[ "$reset_builders" ]]; then
    extend_nix_config builders "$builders_str"
elif [[ "$builders_str" ]]; then
    # There's no way to extend an existing list of builders, so we need to
    # explicitly set the new config to include.  That might be in the
    # environment or might be in a config file, so just use `nix config show`
    # to get the current value.
    existing_builders="$(nix config show builders)"
    if [[ "$existing_builders" = *@* ]]; then
        # TODO implement handling builder files
        exit 69
    else
        extend_nix_config builders "${existing_builders:+"$existing_builders; "}$builders_str"
    fi
fi

if (( ${#overlays[*]} > 0 )); then
    compile_overlays "${overlays[@]}"
    set -- "$@" --arg overlays "$COMPILED_OVERLAYS"
fi

exec "$@"

# vim: et ts=4
