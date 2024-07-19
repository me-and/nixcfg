#!/usr/bin/env nix-shell
#!nix-shell -i bash -p alejandra -p gitMinimal -p findutils -p gnugrep
set -euo pipefail

git ls-files -z |
	grep -z '\.nix$' |
	xargs -0 alejandra -c
