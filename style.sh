#!/usr/bin/env nix-shell
#!nix-shell -i bash -p alejandra -p findutils
set -euo pipefail

find_args=(
	\(
		\(
			-path ./.git
			-o -name hardware-configuration.nix
		\)
		-prune
	\)
	-o \(
		-type f
		-name '*.nix'
		-exec alejandra -c {} +
	\)
)

find . "${find_args[@]}"
