blocks=
blocks_set=

new_args=()

for arg; do
	case "$arg" in

		# Only one `blocks` UDA is allowed on a command line -- if
		# there are more than one, the last takes effect.  I want
		# `blocks` to work more like `depends`, however, where multiple
		# value get merged, so do that.
		blocks:*)
			blocks="${blocks:+"$blocks",}${arg#blocks:}"
			blocks_set=Yes
			;;

		# Allow the filter "project.sub:x" to include tasks with a
		# project of "x" or "x.y", but not "xx", which the regular
		# filters would pick up, and vice versa.
		project.sub:*)
			val="${arg#project.sub:}"
			new_args+=(\( project.is:"$val" or project:"$val". \))
			;;
		project.nsub:*)
			val="${arg#project.nsub:}"
			new_args+=(\( project.isnt:"$val" project.not:"$val". \))
			;;

		*)
			new_args+=("$arg")
			;;
	esac
done

if [[ "$blocks_set" ]]; then
	new_args+=("blocks:$blocks")
fi

exec task "${new_args[@]}"
