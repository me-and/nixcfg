final: prev: {
  fetchGitHubPatch = {
    owner,
    repo,
    commit,
    ...
  } @ args:
    final.fetchpatch (
      {url = "https://github.com/${owner}/${repo}/commit/${commit}.patch";}
      // builtins.removeAttrs args ["owner" "repo" "commit"]
    );
}
