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
