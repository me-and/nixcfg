# Avoid warnings about not being able to find glyphnames.json.
# https://github.com/NixOS/nixpkgs/pull/508732
final: prev: {
  nerd-font-patcher = prev.nerd-font-patcher.overrideAttrs (prevAttrs: {
    installPhase = prevAttrs.installPhase or "" + ''
      cp glyphnames.json $out/share/glyphnames.json
    '';
    postPatch = prevAttrs.postPatch or "" + ''
      substituteInPlace font-patcher \
        --replace-fail "'glyphnames.json'" "'../share/glyphnames.json'"
    '';
  });
}
