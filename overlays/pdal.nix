# https://github.com/NixOS/nixpkgs/issues/541085
# https://github.com/NixOS/nixpkgs/pull/541146
final: prev:
let
  lib = final.lib;

  pdal = prev.pdal.overrideAttrs (
    finalAttrs: prevAttrs: {
      version = "2.10.2";
      src = prevAttrs.src.override {
        tag = finalAttrs.version;
        hash = "sha256-VxELHAiiFMKjsvgBK4Cm6YJSrs/4QhhF1haZv4/FlZg=";
      };
      disabledTests = (lib.remove "pdal_io_copc_reader_test" prevAttrs.disabledTests) ++ [
        "pdal_io_copc_remote_reader_test"
      ];
    }
  );
in
{
  pdal =
    lib.warnIf (lib.versionAtLeast prev.pdal.version pdal.version) "possibly unnecessary pdal overlay"
      pdal;
}
