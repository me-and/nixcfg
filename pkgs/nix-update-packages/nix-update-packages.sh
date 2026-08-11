#!/usr/bin/env bash
set -euo pipefail

export PATH
export NIXPKGS_ALLOW_BROKEN=1

push=
create_prs=
use_local=
while (( $# > 0 )); do
	case "$1" in
	--push)
		push=YesPlease
		shift
		;;
	--pr)
		create_prs=YesPlease
		shift
		;;
	--use-local)
		use_local=YesPlease
		shift
		;;
	*)
		printf 'unexpected argument: %q\n' "$1" >&2
		exit 64
		;;
	esac
done

get_updateable_packages() {
	nix eval --impure --json --apply 'import ./updateable-packages.nix' .#packages.x86_64-linux |
		jq --raw-output0 '.[]'
}

if [[ -z "$use_local" ]]; then
	start_dir="$PWD"
	workdir="$(mktemp --directory --tmpdir "nix-update-packages.$$.XXXXX")"
	git worktree add --detach "$workdir"
	trap 'cd -- "$start_dir" && git worktree remove --force "$workdir"' EXIT
	cd -- "$workdir"
fi

start_ref="$(git rev-parse HEAD)"

exec {pkgs_fd}< <(get_updateable_packages)
pkgs_pid="$!"

while read -d '' -r -u "$pkgs_fd" pkg; do
	if git fetch origin pkg-updates/"$pkg"; then
		git switch pkg-updates/"$pkg"
	else
		git switch -c pkg-updates/"$pkg" "$start_ref"
	fi

	pkg_start_ref="$(git rev-parse HEAD)"

	nix-update \
		--flake \
		--commit \
		--use-update-script \
		"$pkg"
	new_ref="$(git rev-parse HEAD)"

	if [[ "$pkg_start_ref" != "$new_ref" ]]; then
		# Need `--impure` to pick up NIXPKGS_ALLOW_BROKEN.
		was_broken="$(nix eval --impure .?rev="$pkg_start_ref"#packages.x86_64-linux."$pkg".meta.broken)"
		is_broken="$(nix eval --impure .?rev="$new_ref"#packages.x86_64-linux."$pkg".meta.broken)"
		if [[ "$was_broken" = "$is_broken" || "$is_broken" = 'false' ]]; then
			# Either we're fixing something or it wasn't broken in the first place, so carry on.
			if [[ "$push" ]]; then
				git push --force-with-lease origin pkg-updates/"$pkg"
			else
				echo "::notice title=Not pushing pkg-updates/$pkg::nix-update-packages called without \`--push\`, so updates to the pkg-updates/$pkg branch aren't being pushed"
			fi

			mapfile -t open_prs < <(gh pr list --head pkg-updates/"$pkg" --json number --jq '.[].number')
			wait "$!"
			if (( ${#open_prs[*]} == 0 )); then
				if [[ "$create_prs" ]]; then
					gh pr create \
						--fill \
						--base main \
						--head pkg-updates/"$pkg"
				else
					echo "::notice title=Not creating PR for $pkg::nix-update-packages called without \`--pr\`, so no PR is being created for $pkg"
				fi
			elif (( ${#open_prs[*]} == 1 )); then
				echo "::warning title=$pkg PR already exists::No new PR created for $pkg as $GITHUB_SERVER_URL/$GITHUB_REPOSITORY/pull/${open_prs[0]} already exists"
			else
				echo "::error title=Multiple conflicting PRs exist::Multiple pull requests seem to exist for the flake-update branch: ${open_prs[*]} $GITHUB_SERVER_URL/$GITHUB_REPOSITORY/pulls?q=is%3Apr+is%3Aopen+head%3Aflake-update"
				exit 76
			fi
		elif [[ "$is_broken" ]]; then
			echo "::warning::Not pushing broken version of $pkg" >&2
		fi
	else
		# No changes, so clean up the branch we created.
		git switch --detach
		git branch --delete pkg-updates/"$pkg"
	fi
done
wait "$pkgs_pid"
