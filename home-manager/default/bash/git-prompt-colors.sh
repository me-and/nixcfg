override_git_prompt_colors() {
	GIT_PROMPT_THEME_NAME="Custom"

	case "$HOSTNAME" in
		*.tastycake.net)
			HOST_COLOUR="${Blue}"
			PWD_COLOUR="${Green}"
			TIME_COLOUR="${Cyan}"
			;;

		*)
			HOST_COLOUR="${White}"
			PWD_COLOUR="${White}"
			TIME_COLOUR="${White}"
			;;

	esac

	local user_prompt root_prompt
	if [[ "$OSTYPE" = cygwin ]]; then
		# The Git prompt is painfully slow, particularly for larger repos, so
		# disable it.
		GIT_PROMPT_DISABLE=1

		# Admin prompts on Cygwin don't have EUID 0, so the built-in Bash
		# checks don't work.  Check by testing the output of `id` instead.
		local prompt='$'
		if [[ " $(id -G) " = *' 544 '* ]]; then
			user_prompt="${Red}#${ResetColor}"
		else
			user_prompt='$'
		fi
		root_prompt="$user_prompt"
	else
		# '\$' means show '#' if we're root, and '$' otherwise.
		user_prompt='\$'
		root_prompt="$Red"'\$'"$ResetColor"
	fi

	local lvl_mark
	if (( SHLVL == 1 )); then
		lvl_mark=1
	else
		lvl_mark="${Magenta}${SHLVL}${ResetColor}"
	fi

	local prompt_end_lead='\n_TEMP_PLACEHOLDER__BATTERY_PLACEHOLDER_'"$TIME_COLOUR"'\D{%a %e %b %R}'"$ResetColor"

	GIT_PROMPT_END_USER="$prompt_end_lead ${lvl_mark}${user_prompt} "
	GIT_PROMPT_END_ROOT="$prompt_end_lead ${lvl_mark}${root_prompt} "

	GIT_PROMPT_START_USER='\n_LAST_COMMAND_INDICATOR_ '"$HOST_COLOUR"'\u@\h '"$PWD_COLOUR"'\w'"$ResetColor"
	GIT_PROMPT_START_ROOT="$GIT_PROMPT_START_USER"
}

prompt_callback() {
	gp_set_window_title '\h:\w'
}

reload_git_prompt_colors Custom

# vim: ft=bash noet ts=4
