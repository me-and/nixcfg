#!/usr/bin/env nix-shell
#!nix-shell -i bash -p alejandra -p gitMinimal -p findutils -p gnugrep
set -euo pipefail

git ls-files -z |
	grep -z '\.nix$' |
	grep -vxz 'overlays/home-manager/home-manager.nix' |
	xargs -0 alejandra -c
