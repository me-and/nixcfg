# Just because I keep needing it.
{
  mylib,
  python3,
  asmodeus,
}:
mylib.stripChecks (
  python3.withPackages (python3Packages: [ (asmodeus.override { inherit python3Packages; }) ])
)
