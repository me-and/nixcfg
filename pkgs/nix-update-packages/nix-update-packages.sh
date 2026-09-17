#!/usr/bin/env bash
set -euo pipefail

export PATH
export NIXPKGS_ALLOW_BROKEN=1

declare -ir EX_USAGE=64
declare -ir EX_SOFTWARE=70

declare -r system=x86_64-linux

push=
create_prs=
use_local=
debug=
package_list=()
package_list_mode=
while (( $# > 0 )); do
	case "$1" in
	--debug)
		debug=YesPlease
		shift
		;;
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
	-p)
		if [[ -z "$package_list_mode" || "$package_list_mode" = include ]]; then
			package_list+=("$2")
			package_list_mode=include
			shift 2
		else
			echo 'cannot use both -p and -P' >&2
			exit "$EX_USAGE"
		fi
		;;
	-P)
		if [[ -z "$package_list_mode" || "$package_list_mode" = exclude ]]; then
			package_list+=("$2")
			package_list_mode=exclude
			shift 2
		else
			echo 'cannot use both -p and -P' >&2
			exit "$EX_USAGE"
		fi
		;;
	-[pP]*)
		set -- "-${1: 1:1}" "${1: 2}" "${@: 2}"
		;;
	*)
		printf 'unexpected argument: %q\n' "$1" >&2
		exit "$EX_USAGE"
		;;
	esac
done

updateable_packages_f="$(mktemp --tmpdir "nix-update-packages.$$.XXXXX")"
if [[ "$debug" ]]; then
	echo "will not delete package list file $updateable_packages_f" >&2
else
	trap 'rm -f "$updateable_packages_f"' EXIT
fi

if [[ -z "$use_local" ]]; then
	start_dir="$PWD"
	workdir="$(mktemp --directory --tmpdir "nix-update-packages.$$.XXXXX")"
	git worktree add --detach "$workdir"
	trap 'cd -- "$start_dir" && git worktree remove --force "$workdir"' EXIT
	cd -- "$workdir"
fi

start_ref="$(git rev-parse HEAD)"

nix eval --impure --json --apply 'import ./updateable-packages.nix' ".#packages.$system" |
	jq --raw-output0 '.[]' >"$updateable_packages_f"

case "$package_list_mode" in
	include)
		# Make sure the packages specified are all included in the list
		# of updateable packages.
		for pkg in "${package_list[@]}"; do
			if grep -qFzx -e "$pkg" -- "$updateable_packages_f"; then
				echo "package $pkg not updateable" >&2
				exit "$EX_USAGE"
			fi
		done

		packages_to_update=("${package_list[@]}")
		;;
	exclude)
		grep_args=()

		# Make sure the packages specified are all included in the list
		# of updateable packages.
		for pkg in "${package_list[@]}"; do
			if grep -qFzx -e "$pkg" -- "$updateable_packages_f"; then
				echo "package $pkg not updateable" >&2
				exit "$EX_USAGE"
			fi
			grep_args+=(-e "$pkg")
		done

		# shellcheck disable=SC2312 # Checked with `wait "$!"`
		mapfile -d '' -t packages_to_update < <(grep -Fzxv "${grep_args[@]}")
		wait "$!"
		;;
	'')
		mapfile -d '' -t packages_to_update <"$updateable_packages_f"
		;;
	*)
		echo "unexpected package list mode $package_list_mode" >&2
		exit "$EX_SOFTWARE"
		;;
esac

for pkg in "${packages_to_update[@]}"; do
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
		was_broken="$(nix eval --impure ".?rev=$pkg_start_ref#packages.$system.$pkg.meta.broken")"
		is_broken="$(nix eval --impure ".?rev=$new_ref#packages.$system.$pkg.meta.broken")"
		if [[ "$was_broken" = "$is_broken" || "$is_broken" = 'false' ]]; then
			# Either we're fixing something or it wasn't broken in the first place, so carry on.
			if [[ "$push" ]]; then
				git push --force-with-lease origin pkg-updates/"$pkg"
			else
				echo "::notice title=Not pushing pkg-updates/$pkg::nix-update-packages called without \`--push\`, so updates to the pkg-updates/$pkg branch aren't being pushed"
			fi

			# shellcheck disable=SC2312 # Checked with `wait "$!"`
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
