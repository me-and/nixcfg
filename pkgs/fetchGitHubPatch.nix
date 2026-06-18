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
  // removeAttrs args [
    "owner"
    "repo"
    "commit"
  ]
)
