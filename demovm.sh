#!/usr/bin/env bash
set -euo pipefail

rm -f -- demo.qcow2

TMPDIR="$(mktemp -d)"
export TMPDIR
trap 'rm -rf -- "$TMPDIR"' EXIT

nom build .#nixosConfigurations.demo.config.system.build.vm --out-link "$TMPDIR"/demo

export NIX_DISK_IMAGE="$TMPDIR"/demo.qcow2
"$TMPDIR"/demo/bin/run-demo-vm
