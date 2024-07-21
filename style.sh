#!/usr/bin/env nix-shell
#!nix-shell -i bash -p alejandra -p findutils
set -euo pipefail

find . -path ./.git -prune -o -type f -name '*.nix' -exec alejandra -c {} +
