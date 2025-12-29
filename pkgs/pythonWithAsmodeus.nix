# Just because I keep needing it.
{
  python3,
  asmodeus,
}:
python3.withPackages (python3Packages: [ (asmodeus.override { inherit python3Packages; }) ])
