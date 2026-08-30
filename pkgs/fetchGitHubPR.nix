# TODO Move to using fetchpatch2.  Beware of
# https://github.com/NixOS/nixpkgs/issues/257446 in so doing.
{ fetchpatch }:
{
  owner,
  repo,
  pr,
  ...
}@args:
fetchpatch (
  {
    url = "https://github.com/${owner}/${repo}/pull/${toString pr}.patch";
  }
  // removeAttrs args [
    "owner"
    "repo"
    "pr"
  ]
)
