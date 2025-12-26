#!@runtimeShell@

set -euo pipefail
export PATH=@PATH@

help () {
	printf '%s [options] [--] [folder-list]\n\n' "$(basename "$0")"
	printf 'Non-folder options:\n'
	printf '  -F:  Stop existing syncs if needed to run this sync\n'
	printf '       immediately\n'
	printf "  -w:  Don't return until the sync is done\\n"
	printf '  -l:  Show log output (implies -w)\n'
	printf '  -h:  Print this help and exit\n'
	printf '  -e <account>:\n'
	printf '       Email account to sync\n'
	printf '\n'
	printf 'Folder options:\n'
	printf '  -a:  Sync all folders\n'
	printf '  -i:  Sync INBOX\n'
	printf '  -A:  Sync [Gmail]/All Mail\n'
	printf '  -b:  Sync [Gmail]/Bin\n'
	printf '  -d:  Sync [Gmail]/Drafts\n'
	printf '  -f:  Sync [Gmail]/Starred (aka "flagged")\n'
	printf '  -s:  Sync [Gmail]/Sent Mail\n'
	printf '  -S:  Sync [Gmail]/Spam\n'
	printf '\n'
	{
		echo 'You can specify folders to sync by using switches as'
		echo 'above, by specifying folders by name as arguments after'
		echo 'any switches, or a mixture of the two.'
	} | fmt
}

sync_all=
block_args=(--no-block)
show_logs=
folders=()
force=
account=main
while getopts ':aAbde:fFhilsSw' opt; do
	case "$opt" in
		a)	sync_all=Yes;;
		A)	folders+=('[Gmail]/All Mail');;
		b)	folders+=('[Gmail]/Bin');;
		d)	folders+=('[Gmail]/Drafts');;
		e)	account="$OPTARG";;
		f)	folders+=('[Gmail]/Starred');;
		F)	force=YesPlease;;
		h)	help
			exit 0
			;;
		i)	folders+=(INBOX);;
		l)	block_args=(--wait)
			show_logs=YesPlease
			;;
		s)	folders+=('[Gmail]/Sent Mail');;
		S)	folders+=('[Gmail]/Spam');;
		w)	block_args=(--wait);;
		*)	echo "Unexpected option: -$OPTARG" >&2
			echo "Use \`$(basename "$0") -h\` for help" >&2
			exit 2
			;;
	esac
done
shift "$(( OPTIND - 1 ))"

INSTANCE="$(systemd-escape "$account")"

if [[ -z "$sync_all" ]] && (( $# == 0 )) && (( ${#folders[@]} == 0 )); then
	echo 'Nothing to synchronise!' >&2
	exit 2
fi

if [[ "$show_logs" ]]; then
	journalctl -f --user --lines=0 -uofflineimap-full@"$INSTANCE".{service,timer} -uofflineimap-folder@"$INSTANCE".{service,socket} &
	trap 'kill %1' EXIT
fi

rc=0
if [[ "$sync_all" ]]; then
	if [[ "$force" ]]; then
		systemctl --user stop offlineimap-folder@"$INSTANCE".service || rc="$?"
	fi
	if (( rc == 0 )); then
		systemctl --user start "${block_args[@]}" offlineimap-full@"$INSTANCE".service || rc="$?"
	fi
else
	# Shouldn't be necessary, but making sure the socket exists doesn't do any
	# harm!  Always block for this, because we can't write to the socket if it
	# doesn't exist.
	systemctl --user start offlineimap-folder@"$INSTANCE".socket

	# Get the path to the socket to write to.
	socket_property="$(systemctl --user show --value --property=Listen offlineimap-folder@"$INSTANCE".socket)"
	socket_path="${socket_property%' (FIFO)'}"
	if [[ ! -p "$socket_path" ]]; then
		printf 'Could not find pipe at %s\n' "$socket_path" >&2
		exit 1
	fi

	# Sync any folders requested by name.  Note names with an '&' in them need to
	# be translated to the format used by the remote end; this should match
	# translations in the OfflineIMAP config file.
	for arg; do
		echo "${arg//&/&-}" >"$socket_path"
	done

	# Sync any folders requested by option
	for arg in "${folders[@]}"; do
		echo "$arg" >"$socket_path"
	done

	# Writing to the socket should have started the unit anyway, but running
	# systemctl will (a) make sure we block if we've been asked to, and (b) make
	# sure that the return code of this script reflects the state of the service.
	if [[ "$force" ]]; then
		systemctl --user stop offlineimap-full@"$INSTANCE".service || rc="$?"
	fi
	if (( rc == 0 )); then
		systemctl --user start "${block_args[@]}" offlineimap-folder@"$INSTANCE".service || rc=$?
	fi
fi

if [[ "$show_logs" ]]; then
	kill %1
	trap - EXIT
	wait
fi

exit "$rc"
