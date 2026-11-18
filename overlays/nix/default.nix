final: prev: {
  nixVersions = prev.nixVersions.extend (
    finalNV: prevNV: {
      nix_2_35 = prevNV.nix_2_35.overrideAttrs (prevAttrs: {
        patches = prevAttrs.patches or [ ] ++ [
          ./0001-gc-add-experimental-registration-time-candidate-orde.patch
        ];
      });
    }
  );
}
