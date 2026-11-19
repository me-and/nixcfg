# Sometimes I just want to remove all defined tests from a package, whether
# they're in passthru or not.
{ lib }:
pkg:
(removeAttrs pkg [ "tests" ])
// (lib.optionalAttrs (pkg ? passthru) { passthru = removeAttrs pkg.passthru [ "tests" ]; })
