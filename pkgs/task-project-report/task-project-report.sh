#!@runtimeShell@
set -euo pipefail

export PATH=@PATH@${PATH:+:$PATH}

declare -ir EX_USAGE=64

help () {
	printf '%q [-aPph] [-l <lessoptions>]... [<filter>...]\n' "$0"
	printf '\n'
	printf 'Provide a report of open tasks in TaskWarrior, displayed by\n'
	printf 'project.\n'
	printf '\n'
	printf -- '-a: List all tasks; normally the filter `-COMPLETED\n'
	printf '    -DELETED -PARENT` is applied in addition to any command-\n'
	printf '    line filter.\n'
	printf -- '-P: Disable pagination using less.\n'
	printf '\n'
	printf -- '-p: Force pagination using less regardless of whether\n'
	printf '    stdout is attached to a terminal.\n'
	printf '\n'
	printf -- '-l: Add the given option string to the arguments passed\n'
	printf '    to less.  Can be specified multiple times.  Defaults to\n'
	printf '    -FSR.\n'
	printf '\n'
	printf -- '-h: Print this help message.\n'
}

process_filter_arg () {
	local arg="$1"
	local val
	if [[ "$arg" = project.sub:* ]]; then
		val="${arg#project.sub:}"
		filter+=(\( project.is:"$val" or project:"$val". \))
	elif [[ "$arg" = project.nsub:* ]]; then
		val="${arg#project.nsub:}"
		filter+=(\( project.isnt:"$val" project.not:"$val". \))
	else
		filter+=("$arg")
	fi
}

# Parse arguments manually; we can't use getopts because Taskwarrior's filters
# (e.g. `-PARENT`) make that decidedly non-trivial.
less_opts=()
forbid_pagination=
force_pagination=
include_all=
next_is_less_opts=
remainder_is_all_filter=
filter=()
for arg in "$@"; do
	if [[ "$next_is_less_opts" ]]; then
		less_opts+=("$arg")
		next_is_less_opts=
	elif [[ "$remainder_is_all_filter" ]]; then
		process_filter_arg "$arg"
	elif [[ "$arg" =~ ^-[aPph]+$ ]]; then
		case "$arg" in
			*a*)	include_all=Yes;;&
			*P*)	forbid_pagination=Yes;;&
			*p*)	force_pagination=Yes;;&
			*h*)	help
				exit 0
				;;
		esac
	elif [[ "$arg" =~ ^-[aPph]l ]]; then
		# Note this is only anchored at the start.
		pre_l_arg="${arg%%l*}"
		post_l_arg="${arg#*l}"
		case "$pre_l_arg" in
			*a*)	include_all=Yes;;&
			*P*)	forbid_pagination=Yes;;&
			*p*)	force_pagination=Yes;;&
			*h*)	help
				exit 0
				;;
		esac
		if [[ "$post_l_arg" ]]; then
			less_opts+=("$post_l_arg")
		else
			next_is_less_opts=Yes
		fi
	elif [[ "$arg" = -- ]]; then
		remainder_is_all_filter=Yes
	else
		process_filter_arg "$arg"
	fi
done

if [[ "$forbid_pagination" && "$force_pagination" ]]; then
	printf 'Cannot specify both -p and -P\n\n'
	help
	exit "$EX_USAGE"
elif [[ "$forbid_pagination" ]] && (( "${#less_opts[*]}" > 0 )); then
	printf 'Cannot specify both -P and -l\n\n'
	help
	exit "$EX_USAGE"
fi >&2

if [[ "$force_pagination" || ( -t 0 && ! "$forbid_pagination" ) ]]; then
	paginate=Yes
	if (( "${#less_opts[*]}" == 0 )); then
		less_opts=(-FSR)
	fi
else
	paginate=
fi

if [[ -z "$include_all" ]]; then
	filter+=(-COMPLETED -DELETED -PARENT)
fi

{ task "${filter[@]}" _unique uuid; printf '\0'; task export; } |
	if [[ "$paginate" ]]; then
		jq -Rsrf @script@ |
			less "${less_opts[@]}"
	else
		jq -Rsrf @script@
	fi

# vim: ft=bash noet ts=8
