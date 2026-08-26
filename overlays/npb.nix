final: prev:
# Overlay may be used in contexts where `prev` is essentially an empty set as
# part of my overlay checks, so only attempt to warn if we're in an environment
# where that's possible.
if prev ? lib.warnIf then
  prev.lib.warnIf (prev ? npb) ''
    npb now exists in Nixpkgs, so no longer belongs as a custom package in this
    repository
  '' { }
else
  { }
