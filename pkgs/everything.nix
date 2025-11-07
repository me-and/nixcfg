# A derivation that depends on all the derivations across all architectures in
# self.checks.  Probably not very useful to build, but comparing the before and
# after derivations with something like nix-diff permits seeing what difference
# some change makes across all my systems and packages.
{ linkFarm, inputs }:
linkFarm "everything" (builtins.mapAttrs (n: v: linkFarm n v) inputs.self.checks)
