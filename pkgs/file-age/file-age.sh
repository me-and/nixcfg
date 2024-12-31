#!@runtimeShell@
set -eu

export PATH=@PATH@

declare -ir EX_USAGE=64

human=
force=
while getopts hf opt; do
	case "$opt" in
		h)	human=YesPlease;;
		f)	force=YesPlease;;
		*)	echo "file-age: unexpected argument -$opt" >&2
			exit "$EX_USAGE"
			;;
	esac
done
shift "$((OPTIND - 1))"

if (( $# == 0 )); then
	echo "file-age: no file specified" >&2
	exit "$EX_USAGE"
elif (( $# > 1 )); then
	echo "file-age: multiple files specified" >&2
	exit "$EX_USAGE"
fi

if [[ -e "$1" ]]; then
	then="$(date -r "$1" '+%s')"
elif [[ "$force" ]]; then
	then=0
else
	echo "No such file $1" >&2
	exit 1
fi

diff="$((EPOCHSECONDS - then))"

if [[ "$human" ]]; then
	if (( diff < 60 )); then
		unit='second'
		val="$diff"
	elif (( diff < (60*60) )); then
		unit='minute'
		val="$((diff/60))"
	elif (( diff < (60*60*24) )); then
		unit='hour'
		val="$((diff/60/60))"
	elif (( diff < (60*60*24*7) )); then
		unit='day'
		val="$((diff/60/60/24))"
	elif (( diff < (60*60*24*30) )); then
		unit='week'
		val="$((diff/60/60/24/7))"
	elif (( diff < (60*60*24*365) )); then
		unit='month'
		val="$((diff/60/60/24/30))"
	else
		unit='year'
		val="$((diff/60/60/24/365))"
	fi
	if (( val != 1 )); then
		plural='s'
	else
		plural=
	fi
	printf "%'d %s%s\n" "$val" "$unit" "$plural"
else
	echo "$diff"
fi

# vim: ft=bash noet ts=8
