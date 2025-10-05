final: prev: {
  makemkv = let
    version = "1.18.2";
  in
    final.lib.warnIf (final.lib.versionAtLeast prev.makemkv.version version) "unnecessary overlay upgrade of makemkv"
    prev.makemkv.overrideAttrs (prevAttrs: {
      inherit version;
      srcs = let
        binSrc = final.fetchurl {
          urls = [
            "http://www.makemkv.com/download/makemkv-bin-${version}.tar.gz"
            "http://www.makemkv.com/download/old/makemkv-bin-${version}.tar.gz"
          ];
          hash = "sha256-v8THzrwPAEl2cf/Vbmo08HcKnmr37/LwEn76FD8oY24=";
        };
        ossSrc = final.fetchurl {
          urls = [
            "http://www.makemkv.com/download/makemkv-oss-${version}.tar.gz"
            "http://www.makemkv.com/download/old/makemkv-oss-${version}.tar.gz"
          ];
          hash = "sha256-uUl/VVXCV/XTx/GLarA8dM/z6kQ36ANJ1hjRFb9fpEU=";
        };
      in [binSrc ossSrc];
      sourceRoot = "makemkv-oss-${version}";
      installPhase = builtins.replaceStrings [prevAttrs.version] [version] prevAttrs.installPhase;
    });
}
