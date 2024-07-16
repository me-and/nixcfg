# Patch fetchFromGitHub to support GitHub fine-grained access tokens.
# https://github.com/NixOS/nixpkgs/pull/321484
# TODO This depends on writeCheckedShellScript so it should include that explicitly.
final: prev: {
  fetchFromGitHub = {
    owner,
    repo,
    rev,
    name ? "source",
    private ? false,
    githubBase ? "github.com",
    varPrefix ? null,
    hash,
    useUpstream ? null,
    ...
  } @ args: let
    prevDerivation = prev.fetchFromGitHub (builtins.removeAttrs args ["useUpstream"]);

    myDerivation = let
      varBase =
        if (varPrefix == null)
        then "NIX_GITHUB_PRIVATE_"
        else "NIX_${varPrefix}_GITHUB_PRIVATE_";
    in
      prev.fetchzip {
        inherit name hash;
        url =
          if githubBase == "github.com"
          then "https://api.github.com/repos/${owner}/${repo}/tarball/${rev}"
          else "https://${githubBase}/api/v3/repos/${owner}/${repo}/tarball/${rev}";
        extension = "tar.gz";
        passthru = {gitRepoUrl = "https://${githubBase}/${owner}/${repo}.git";};
        netrcPhase = final.writeCheckedShellScript {
          name = "${name}-netrc.sh";
          text = let
            machineName =
              if githubBase == "github.com"
              then "api.github.com"
              else githubBase;
          in ''
            if [[ -z "''$${varBase}USERNAME" -o -z "''$${varBase}PASSWORD" ]]; then
                echo "Error: Private fetchFromGitHub requires the nix building process (nix-daemon in multi user mode) to have the ${varBase}USERNAME and ${varBase}PASSWORD env vars set." >&2
                exit 1
            fi
            cat >netrc <<EOF
            machine ${machineName}
                    login ''$${varBase}USERNAME
                    password ''$${varBase}PASSWORD
            EOF
          '';
        };
        netrcImpureEnvVars = ["${varBase}USERNAME" "${varBase}PASSWORD"];
      };
  in
    # If the caller explicitly requested my version or the upstream version of
    # fetchFromGitHub, respect that.
    if useUpstream == true
    then prevDerivation
    else if useUpstream == false
    then myDerivation
    # If the previous derivation has a branchName attribute, that means it's
    # using fetchgit rather than fetchzip.  I've not worked out how to emulate
    # that, or even if it's necessary.  Try using the upstream fetchFromGitHub;
    # if it works, great, if it doesn't, I'll need to fix my derivation to
    # handle the scenario.
    else if (prevDerivation ? branchName)
    then prevDerivation
    # Otherwise, use my derivation, which should either get the same result as
    # the upstream derivation anyway, or will work when the upstream derivation
    # wouldn't.
    else myDerivation;
}
