#!/usr/bin/env bash

set -euo pipefail

# Make sure that attempts to call `task` actually reach the task executable.
# This is mostly here for the sake of Nix, so that it has something unambiguous
# to replace with the path to the real task executable.
task () { command task "$@"; }

task_quick_quiet () {
	task rc.color=0 rc.detection=0 rc.gc=0 rc.hooks=0 rc.recurrence=0 rc.verbose=0 "$@"
}

# Used in a boolean context, so must handle any errors itself.
string_in_args () {
	local string="$1"
	shift
	local v
	for v; do
		if [[ "$v" = "$string" ]]; then
			return 0
		fi
	done
	return 1
}

pattern_in_args () {
	local pattern="$1"
	shift
	local v
	for v; do
		if [[ "$v" = $pattern ]]; then
			return 0
		fi
	done
	return 1
}

possible_commands_str="$(task_quick_quiet _commands)"
mapfile -t possible_commands <<<"$possible_commands_str"

config_args=()

for arg; do
	if [[ "$arg" = -- ]]; then
		# Everything else is considered to be command arguments and/or
		# task description arguments.
		break
	elif [[ ! -v command ]] && string_in_args "$arg" "${possible_commands[@]}"; then
		command="$arg"
	elif [[ "$arg" = rc.* ]]; then
		config_args+=("$arg")
	fi
done

if [[ ! -v command ]]; then
	# No command specified, so the command will be the default command.
	command="$(task_quick_quiet _get rc.default.command)"
fi

if [[ "$command" = projects ]] &&
	! pattern_in_args 'rc.list.all.projects[:=]*' "${config_args[@]}"
then
	# User is running the `projects` command and hasn't explicitly added
	# `list.all.projects` configuration, so do something that works better
	# with not routinely running Taskwarrior garbage collection.
	set -- rc.list.all.projects=1 -COMPLETED -DELETED "$@"
fi

exec task "$@"
