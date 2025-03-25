#!@runtimeShell@

set -euo pipefail
shopt -s dotglob

export PATH=@PATH@

if ! command -v ifne &>/dev/null; then
	echo 'git-report requires ifne' >&2
	exit 1
fi

remove_unwanted_branch_names () {
	grep -Eve '\(HEAD detached from [0-9a-f]+\)' -e '\(no branch, bisect started on .+\)' -e '\(HEAD detached at .+\)' -e '\(no branch\)'
}

indent () {
	sed 's/^/  /' "$@"
}

head_and_indent () {
	header="$1"
	shift
	indent "$@" | ifne cat <(echo "${header}:") - <(echo)
}
description_report () {
	local dir="$1"
	local git_dir="$dir"/"$2"
	local description_file="$git_dir"/description
	if [[ -r "$description_file" && -f "$description_file" && -s "$description_file" ]]; then
		if grep -Evq '^Unnamed repository' "$description_file"; then
			head_and_indent 'Description' "$description_file"
		fi
	fi
}

state_report () {
	local dir="$1"
	local git_dir="$dir"/"$2"
	{
		if [[ -e "$git_dir"/BISECT_LOG ]]; then
			echo Bisecting
		fi
		if [[ -e "$git_dir"/sequencer ]]; then
			echo 'Cherry-pick or revert sequence in progress'
		fi
	} | head_and_indent 'Current state'
}

wc_report () {
	local dir="$1"
	git -C "$dir" -c color.status=always status --short | head_and_indent 'Working copy details'
}

branch_report () {
	local longest_br_name
	longest_br_name="$(git -C "$1" branch --format="%(refname:short)" | remove_unwanted_branch_names | wc -L)"
	git -C "$1" branch --format='%(HEAD) %(align:'"$((longest_br_name + 2))"')%(refname:short)%(end)%(upstream:short) %(upstream:track)' | remove_unwanted_branch_names | head_and_indent 'Branch details'
}

stash_report () {
	git -C "$1" stash list | head_and_indent 'Stash details'
}

full_report () {
	local dir="$1"
	local relative_git_dir git_in_work_tree found_subdir
	local rc=0

	relative_git_dir="$(git -C "$dir" rev-parse --git-dir 2>/dev/null || :)"

	if [[ "$relative_git_dir" ]]; then
		# This is a Git directory
		git_in_work_tree="$(git -C "$dir" rev-parse --is-inside-work-tree)"

		if [[ "$check_remotes" ]]; then
			git -C "$dir" fetch -q --all
		fi

		description_report "$dir" "$relative_git_dir"
		state_report "$dir" "$relative_git_dir"
		[[ "$git_in_work_tree" = true ]] && wc_report "$dir"
		branch_report "$dir"
		[[ "$git_in_work_tree" = true ]] && stash_report "$dir" "$relative_git_dir"

	elif [[ "$recurse" ]]; then
		found_subdir=
		for subdir in "$dir"/*; do
			if [[ -d "$subdir" ]]; then
				full_report "$subdir" | head_and_indent "${subdir#./}"
				found_subdir=Yes
			fi
			if [[ -z "$found_subdir" ]]; then
				echo 'No Git directory found'
				rc=1
			fi
		done
	else
		rc=1
	fi

	return "$rc"
}

recurse=
check_remotes=
while getopts ':rR' opt; do
	case "$opt" in
		r)	check_remotes=YesPlease;;
		R)	recurse=YesPlease;;
		*)	printf -- '-%s is not a valid option\n' "$OPTARG" >&2
			exit 64  # EX_USAGE
			;;
	esac
done
shift "$(( OPTIND - 1 ))"

if (( $# == 0 )); then
	full_report .
elif (( $# == 1 )); then
	full_report "$1"
else
	for dir; do
		full_report "$dir" | head_and_indent "$dir"
	done
fi

# vim: ft=bash noet ts=8
