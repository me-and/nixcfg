# Remove a sequence of keys from an object.
#
# jq 'stripkeys("alpha", "beta", "gamma")'
#    {"alpha": 123, "beta": 456, "zeta" 789}
# => {"zeta": 789}
def stripkeys(ks): reduce ks as $k (.; del(.[$k]));

# Compare two objects and print the differences between them.
#
# jq 'diffobjs(.[0]; .[1])'
#    [{"alpha": 123, "beta": 456}, {"alpha": 123, "beta": 567, "gamma": 890}]
# => {"beta": [456, 567], "gamma": [null, 890]}
def diffobjs($l; $r): reduce ($l + $r | keys)[]
                      as $key ({};
                               if $l[$key] != $r[$key]
                               then .[$key] = [$l[$key], $r[$key]]
                               end);

# Group by some particular function.  Similar to INDEX, but can cope with
# mulitple items with identical keys, and also seems to be slightly faster(!).
#
# jq 'index_by(.key)'
#    [{"key": "alpha", "value": 1},
#     {"key": "alpha", "value": 2},
#     {"key": "beta", "value": 2}]
# => {"alpha": [{"key": "alpha", "value": 1},
#               {"key": "beta", "value": 2}],
#     "beta": [{"key": "beta", "value": 2}]}
def index_by(f): group_by(f) | reduce .[] as $a ({}; .[$a[0] | f] = $a);

# Pad a string on the left so it is at least the given number of characters.
# If specified, use the given padding character; if not, use space.
def lpad(n; s): s * (n - length) + .;
def lpad(n): lpad(n; " ");

# vim: et ts=8 ft=jq
