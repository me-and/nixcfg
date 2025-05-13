import "datetime" as datetime {search: "./"};
import "util" as util {search: "./"};

def test: "datetime" | modulemeta;

def _map_key($key; f): if has($key) then .[$key] |= f end;

# Format the date fields in a Taskwarrior export
def fmtdates: reduce ("due", "end", "entry", "modified", "reviewed",
                      "scheduled", "start", "until", "wait")
              as $key (.; _map_key($key; datetime::fmtlocaldate))
              | _map_key("annotations";
                         map(_map_key("entry"; datetime::fmtlocaldate))
                         );

# Compare two tasks and return an object with the fields that differ.
def compare($l; $r):
        [$l, $r]
        | map(util::stripkeys("id", "urgency"))
        | util::diffobjs(.[0]; .[1]);

# Compare two lists of tasks and print out the ones that are different.  Use
# as, for example:
#
#     { task export; ssh user@server task export; } | jq -s 'diff_exports'
def diff_exports_by_attr:
        map(map(util::stripkeys("id", "urgency"))
            | INDEX(.[]; .uuid)
            ) as [$l, $r]
        | reduce ($l + $r | keys)[]
          as $key ({};
                   .[$key] |= (
                           util::diffobjs($l[$key]; $r[$key])
                           | select(length > 0)
                           )
                   );
def diff_exports_by_task:
        map(map(util::stripkeys("id", "urgency"))
            | INDEX(.[]; .uuid)
            ) as [$l, $r]
        | reduce ($l + $r | keys)[]
          as $key ({};
                   .[$key] |= (
                        if $l[$key] == $r[$key]
                        then empty
                        else [$l[$key], $r[$key]]
                        end
                        )
                   );

# vim: et ts=8 ft=jq
