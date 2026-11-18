# TODO Add warnings if version != 2
{ fetchpatch, fetchpatch2 }:
{
  owner,
  repo,
  commit,
  version ? 1,
  ...
}@args:
let
  fetchpatch' =
    if version == 1 then
      fetchpatch
    else if version == 2 then
      fetchpatch2
    else
      throw "fetchGitHubPR `version` argument should be `1` or `2`";
in
fetchpatch' (
  {
    url = "https://github.com/${owner}/${repo}/commit/${commit}.patch";
  }
  // removeAttrs args [
    "owner"
    "repo"
    "commit"
    "version"
  ]
)
