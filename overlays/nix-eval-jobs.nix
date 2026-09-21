# Avoid errors like "evaluation exceeded the memory budget of 4096 MiB (workers
# * max-memory-size) even when run alone" from nix-eval-jobs when evaluating
# things like my NixOS configurations.
#
# TODO Work out what introduced this regression, and report/fix it.
final: prev: {
  nix-eval-jobs = prev.nix-eval-jobs.overrideAttrs (
    finalAttrs: prevAttrs: {
      version = final.lib.warnIf (prevAttrs.version != "2.35.3" && prevAttrs.version != "2.35.4") ''
        Nixpkgs' nix-eval-jobs is v${prevAttrs.version}, which *might* not have
        the bug that requires the overlay in overlays/nix-eval-jobs.nix
      '' "2.35.2";
      src = final.fetchFromGitHub {
        inherit (prevAttrs.src) owner repo;
        tag = "v${finalAttrs.version}";
        hash = "sha256-qHxk1wVKqz/UMtVC14ugkhySbqYcRQbwobyeO/fhAf0=";
      };
      buildInputs =
        let
          parts = builtins.partition (p: p != final.mimalloc) prevAttrs.buildInputs;
        in
        assert builtins.length parts.wrong == 1;
        parts.right;
    }
  );
}
