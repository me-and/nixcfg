#!/usr/bin/env bash
set -euo pipefail

export PATH
export NIXPKGS_ALLOW_BROKEN=1

get_updateable_packages() {
	nix eval --impure --json --apply 'import ./updateable-packages.nix' .#packages.x86_64-linux |
		jq --raw-output0 '.[]'
	false
}

start_ref="$(git rev-parse HEAD)"

while read -d '' -r pkg; do
	git switch -c pkg-updates/"$pkg" "$start_ref"
	nix-update \
		--flake \
		--commit \
		--use-update-script \
		"$pkg"
	new_ref="$(git rev-parse HEAD)"

	if [[ "$start_ref" != "$new_ref" ]]; then
		was_broken="$(nix eval --impure .?rev="$start_ref"#packages.x86_64-linux."$pkg".meta.broken)"
		is_broken="$(nix eval --impure .?rev="$new_ref"#packages.x86_64-linux."$pkg".meta.broken)"
		if [[ "$was_broken" = "$is_broken" || "$is_broken" = 'false' ]]; then
			# Either we're fixing something or it wasn't broken in the first place, so carry on.
			git push --force origin pkg-updates/"$pkg"
			gh pr create \
				--fill \
				--base main \
				--head pkg-updates/"$pkg"
		elif [[ "$is_broken" ]]; then
			echo "::warning::Not pushing broken version of $pkg" >&2
		fi
	fi
done < <(get_updateable_packages)
