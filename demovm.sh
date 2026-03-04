#!/usr/bin/env bash
set -euo pipefail

TMPDIR="$(mktemp -d)"
export TMPDIR
trap 'rm -rf -- "$TMPDIR"' EXIT

if [[ "${BASH_SOURCE[0]}" = */* ]]; then
	flake_path="${BASH_SOURCE[0]%/*}"
else
	flake_path=.
fi

nom build "$flake_path"#nixosConfigurations.demo.config.system.build.vm --out-link "$TMPDIR"/demo

export NIX_DISK_IMAGE="$TMPDIR"/demo.qcow2
"$TMPDIR"/demo/bin/run-demo-vm
