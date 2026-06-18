final: prev:
let
  patch = final.mypkgs.fetchGitHubPR {
    owner = "OfflineIMAP";
    repo = "offlineimap3";
    pr = "251";
    hash = "sha256-zdqRk8A91YkhNgcmlGGN4F2KBbaRDtVMw7RcK5e237Q=";
  };
in
{
  offlineimap = prev.offlineimap.overrideAttrs (prevAttrs: {
    patches = prevAttrs.patches or [ ] ++ [ patch ];
  });
}
