#!@runtimeShell@
set -euo pipefail

export PATH=@PATH@

source_files=()
opusenc_args=()
force=
bad_args=()
while (( $# > 0 )); do
	case "$1" in
		# Not attempting to emulate all the opusenc options, just the
		# key ones I care about.
		--music|--speech)
			opusenc_args+=("$1")
			shift
			;;
		-f|--force)
			force=YesPlease
			shift
			;;
		-x)	set -x
			shift
			;;

		# Break apart merged option switches.
		-[fx]*)
			set -- "-${1: 1:1}" "-${1: 2}" "${@: 2}"
			;;

		# Anything after a -- should be treated as a file.
		--)	shift
			source_files+=("$@")
			break
			;;

		# Error on any unrecognised option switches.
		-*)	bad_args+=("$1")
			shift
			;;

		# Anything that doesn't look like an option is a file.
		*)	source_files+=("$1")
			shift
			;;
	esac
done

# Permit .wav or .WAV or .wAv...
shopt -s nocasematch

for arg in "${source_files[@]}"; do
	if [[ "$arg" != *.wav ]]; then
		bad_args+=("$arg")
	fi
done

if (( ${#bad_args[*]} > 0 )); then
	printf 'Unexpected arguments:\n'
	printf '%s\n' "${bad_args[@]@Q}"
	exit 64 # EX_USAGE
fi >&2

for arg in "${source_files[@]}"; do
	target="${arg%.wav}.opus"
	if [[ "$force" || ! -e "$target" ]]; then
		opusenc "${opusenc_args[@]}" -- "$arg" "$target"
		touch --no-create --reference="$arg" -- "$target"
	else
		printf 'File exists: %s\n' "${target}" >&2
		exit 73 # EX_CANTCREAT
	fi
done
