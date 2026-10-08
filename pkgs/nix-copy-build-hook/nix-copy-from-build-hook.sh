#!@BASH@
set -euo pipefail
shopt -s nullglob
export PATH=@PATH@

targets=()
nix_copy_args=()
while (( $# > 0 )); do
	case "$1" in
		--substitute-on-destination|-s)
			nix_copy_args+=(--substitute-on-destination)
			shift
			;;
		--)
			shift
			targets+=("$@")
			break
			;;
		*)
			targets+=("$1")
			shift
			;;
	esac
done

if (( ${#targets[*]} == 0 )); then
	exit 64
fi

did_something=

while :; do
	paths=(/tmp/nix-copy-post-build-hook/*)

	if (( ${#paths[*]} == 0 )); then
		if [[ "$did_something" ]]; then
			echo 'finished' >&2
		else
			echo 'nothing to copy' >&2
		fi
		exit 0
	fi

	for target in "${targets[@]}"; do
		nix copy "${nix_copy_args[@]}" --to "$target" "${paths[@]}"
	done

	rm -- "${paths[@]}"

	did_something=Yes
done
