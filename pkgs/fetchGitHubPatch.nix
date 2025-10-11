{ fetchpatch }:
{
  owner,
  repo,
  commit,
  ...
}@args:
fetchpatch (
  {
    url = "https://github.com/${owner}/${repo}/commit/${commit}.patch";
  }
  // builtins.removeAttrs args [
    "owner"
    "repo"
    "commit"
  ]
)
