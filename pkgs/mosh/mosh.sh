#!@runtimeShell@

export PATH=@PATH@

set -euo pipefail

skip_next=
# Disable unused variable warnings as, if this is used, it'll most likely be in
# the moshrc file.
# shellcheck disable=SC2034
remote=
remote_is_next=
ports_specified=
port_args=()
family_args=(--family=prefer-inet6)

# Looping over the arguments is significantly easier as mosh itself
# cannot cope with combining short arguments -- `-n -6` cannot be
# shortened to `-n6` -- so the argument parsing can just emulate mosh'\''s
# own limitations.
for arg; do
	if [[ "$skip_next" ]]; then
		# Previous argument indicated the next one should be
		# skipped, so do so and clear that flag.
		skip_next=
		continue
	fi

	if [[ "$remote_is_next" ]]; then
		# Previous argument indicated the next one would be the
		# remote specifier, so remove any optional username and
		# record the host.  This will always be the last
		# argument that needs special handling by this wrapper.
		remote="${arg#*@}"
		break
	fi

	case "$arg" in
		--port=*)
			# Long port number option, so the ports have
			# been explicitly specified.
			#
			# Disable unused variable warnings as, if this is used,
			# it'll most likely be in the moshrc file.
			# shellcheck disable=SC2034
			ports_specified=Yes
			;;
		-p)
			# Short port number option, so the next
			# argument should be a port number or number
			# range, and the ports have been explicitly
			# specified.
			skip_next=Yes
			# Disable unused variable warnings as, if this is used,
			# it'll most likely be in the moshrc file.
			# shellcheck disable=SC2034
			ports_specified=Yes
			;;
		-4|-6|--family=*)
			# Options specify the IP address family, so
			# respect that rather than overriding it.
			family_args=()
			;;
		--)
			# End of option marker.  If we get to this, the
			# next argument must be the host.
			remote_is_next=Yes
			;;
		--*)
			# Long argument.  We can ignore these.
			;;
		*)
			# Must be the host, possibly with a username prepended.
			#
			# Disable unused variable warnings as, if this is used,
			# it'll most likely be in the moshrc file.
			# shellcheck disable=SC2034
			remote="${arg#*@}"
			break
			;;
	esac
done

# moshrc is just a Bash script for setting up values I want to be configurable,
# e.g. specific ports to use for specific hosts.
config_file="${MOSHRC:-"${XDG_CONFIG_HOME:-"$HOME"/.config}"/moshrc}"
if [[ -r "$config_file" ]]; then
	 # shellcheck source=/dev/null
	. "$config_file"
fi

mosh "${port_args[@]}" "${family_args[@]}" "$@"
