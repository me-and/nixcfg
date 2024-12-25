# https://github.com/NixOS/nixpkgs/pull/367376
final: prev: let
  boost183OrBetter =
    if final.lib.versionAtLeast final.boost.version "1.83"
    then final.boost
    else final.boost183;
  opencascade-occt_7_6_1 = final.opencascade-occt.overrideAttrs {
    pname = "opencascade-occt";
    version = "7.6.1";
    src = final.fetchFromGitHub {
      owner = "Open-Cascade-SAS";
      repo = "OCCT";
      rev = "V7_6_1";
      sha256 = "sha256-C02P3D363UwF0NM6R4D4c6yE5ZZxCcu5CpUaoTOxh7E=";
    };
  };
in {
  prusa-slicer =
    if final.lib.versionAtLeast prev.prusa-slicer.version "2.9.0"
    then
      final.lib.warn "unnecessary version override in prusa.nix"
      prev.prusa-slicer
    else
      prev.prusa-slicer.overrideAttrs (prevAttrs: {
        version = "2.9.0";
        patches = [];
        src = final.fetchFromGitHub {
          owner = "prusa3d";
          repo = "PrusaSlicer";
          hash = "sha256-6BrmTNIiu6oI/CbKPKoFQIh1aHEVfJPIkxomQou0xKk=";
          rev = "version_2.9.0";
        };
        postPatch = "";
        buildInputs =
          [final.webkitgtk_4_0]
          ++ (map (
              p:
                if p.pname == "boost"
                then boost183OrBetter
                else if p.pname == "opencascade-occt"
                then opencascade-occt_7_6_1
                else p
            )
            prevAttrs.buildInputs);
        cmakeFlags = prevAttrs.cmakeFlags ++ ["-DCMAKE_CXX_FLAGS=-DBOOST_LOG_DYN_LINK"];
      });
}
