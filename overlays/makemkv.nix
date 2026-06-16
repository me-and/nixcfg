# Something odd going on with https://www.makemkv.com, so work around that.
final: prev: {
  makemkv = prev.makemkv.overrideAttrs (
    prevAttrs:
    assert prevAttrs.version == "1.18.3";
    {
      passthru.srcs = {
        bin = final.fetchurl {
          urls = prevAttrs.passthru.srcs.bin.urls ++ [
            "https://web.archive.org/web/20260127045011if_/https://www.makemkv.com/download/makemkv-bin-1.18.3.tar.gz"
          ];
          hash = prevAttrs.passthru.srcs.bin.outputHash;
        };

        oss = final.fetchurl {
          urls = prevAttrs.passthru.srcs.oss.urls ++ [
            "https://web.archive.org/web/20260228033027if_/https://www.makemkv.com/download/makemkv-oss-1.18.3.tar.gz"
          ];
          hash = prevAttrs.passthru.srcs.oss.outputHash;
        };
      };
    }
  );
}
