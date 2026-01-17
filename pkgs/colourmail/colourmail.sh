#!@runtimeShell@

export PATH=@PATH@

set -eu

# Implement an interface that means this could be used as a drop-in replacement
# for the version of `mail` provided by Debian's bsd-mailx package.
check_empty=
test_mode=
header_args=()
ansi2html_args=(--light-background)
while getopts ':a:b:Bc:dEfIiNnr:s:tu:v' opt; do
	case "$opt" in
		a)	header_args+=(--header "$OPTARG");;
		b)	header_args+=(--bcc "$OPTARG");;
		B)	ansi2html_args=();;
		c)	header_args+=(--cc "$OPTARG");;
		E)	check_empty=YesPlease;;
		r)	header_args+=(--header "From: $OPTARG");;
		s)	header_args+=(--subject "$OPTARG");;
		t)	test_mode=YesPlease;;
		d|f|I|i|N|n|u|v)
			printf -- '-%s is not implemented!\n' "$opt" >&2
			exit 70  # EX_SOFTWARE
			;;
		*)	printf -- '-%s is not a valid option!\n' "$OPTARG" >&2
			exit 64  # EX_USAGE
			;;
	esac
done

# Check necessary commands exist.  Exit with an error code if we're in test
# mode (because the caller wants to handle the scenario itself), otherwise exec
# mail as something that can (hopefully) handle things for us.
{ command -v mime-construct && command -v ansi2txt && command -v ansi2html; } >/dev/null || {
	echo 'Missing one of mime-construct, ansi2txt or ansi2html' >&2
	[[ "$test_mode" ]] && exit 69  # EX_UNAVAILABLE
	echo 'Falling back to mail' >&2
	exec mail "$@"
}

# If we're in test mode, don't do any more work.
[[ "$test_mode" ]] && exit 0

shift "$(( OPTIND - 1 ))"
for arg; do
	header_args+=(--to "$arg")
done

tempdir="$(mktemp -d colourmail.$$.XXXXX)"
trap 'rm -rf -- "$tempdir"' EXIT

input_file="$tempdir"/input
text_file="$tempdir"/text
html_file="$tempdir"/html

cat >"$input_file"

[[ "$check_empty" && ! -s "$input_file" ]] && exit 0

ansi2txt <"$input_file" >"$text_file"
ansi2html "${ansi2html_args[@]}" <"$input_file" >"$html_file"

mime-construct "${header_args[@]}" --multipart 'multipart/alternative' --file "$text_file" --type 'text/html' --file "$html_file"

# vim: ft=bash noet ts=8
