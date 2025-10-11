# wslu blocks using bash -x for some reason.  I want to be able to use bash -x!
# Patch that out.
#
# Granted, wslu does have a --verbose option that effectively re-enables `set
# -x`, but I don't want to have to remember that that's what this means in this
# context when I can just remember the standard Bash features.
final: prev: {
  wslu = prev.wslu.overrideAttrs (prevAttrs: {
    patches = (prevAttrs.patches or [ ]) ++ [ ./set-x.diff ];
  });
}
