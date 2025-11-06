# For everything in mylib, recurse until I either find a derivation, which
# should be built, or an attrset with a `tests` attribute, in which case call
# `lib.runTests` on that attribute value and assert that there are no test
# failures.
#
# This interface is very tentative!  It's vaguely based on what I see in
# Nixpkgs' lib/tests, but with the expectation that tests would be defined
# alongside my library functions.  This requires defining functions using the
# `__functor` attribute.  Thus, as a trivial example,
#
#     const = x: y: x
#
# would be redefined as
#
#     const = {
#       __functor = self: x: y: x;
#       tests = {
#         testInt = {
#           expr = const 1 2;
#           expected = 1;
#         };
#       };
#     }
#
# TODO: I think the above example might not work as-is: where is `const`
# defined for use in the definition of `testInt`?
{ lib, mylib }:
let
  testsOrEmptySets = lib.mapAttrsRecursiveCond (v: !(lib.isDerivation v || v ? tests)) (
    p: v:
    if lib.isDerivation v then
      v
    else
      assert lib.runTests (v.tests or { }) == [ ];
      { }
  ) mylib;
in
lib.converge (lib.filterAttrsRecursive (n: v: v != { })) testsOrEmptySets
