override_git_prompt_colors() {
	GIT_PROMPT_THEME_NAME="Custom"

	case "$HOSTNAME" in
		*)
			HOST_COLOUR="${White}"
			PWD_COLOUR="${White}"
			TIME_COLOUR="${White}"
			;;

	esac

	local user_prompt root_prompt
	# '\$' means show '#' if we're root, and '$' otherwise.
	user_prompt='\$'
	root_prompt="$Red"'\$'"$ResetColor"

	local lvl_mark
	if (( SHLVL == 1 )); then
		lvl_mark=1
	else
		lvl_mark="${Magenta}${SHLVL}${ResetColor}"
	fi

	local prompt_end_lead='\n_TEMP_PLACEHOLDER__BATTERY_PLACEHOLDER_'"$TIME_COLOUR"'\D{%a %e %b %R}'"$ResetColor"

	GIT_PROMPT_END_USER="$prompt_end_lead ${lvl_mark}${user_prompt} "
	GIT_PROMPT_END_ROOT="$prompt_end_lead ${lvl_mark}${root_prompt} "

	GIT_PROMPT_START_USER='_LAST_COMMAND_INDICATOR_ '"$HOST_COLOUR"'\u@\h '"$PWD_COLOUR"'\w'"$ResetColor"
	GIT_PROMPT_START_ROOT="$GIT_PROMPT_START_USER"
}

prompt_callback() {
	gp_set_window_title '\h:\w'
}

reload_git_prompt_colors Custom

# vim: ft=bash noet ts=4
