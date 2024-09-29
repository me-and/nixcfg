#!/usr/bin/env nix-shell
#!nix-shell -i bash -p alejandra -p findutils
set -euo pipefail

command=(alejandra -c)
while (( $# > 0 )); do
	if [[ "$1" = '-f' || "$1" = '--fix' ]]; then
		command=(alejandra)
		shift
	else
		printf 'Unrecognised argument: %s\n' "$1" >&2
		exit 64 # EX_USAGE
	fi
done

find_args=(
	\(
		\(
			-path ./.git
			-o -path './nixos/*-hardware.nix'
		\)
		-prune
	\)
	-o \(
		-type f
		-name '*.nix'
		-exec "${command[@]}" {} +
	\)
)

find . "${find_args[@]}"
