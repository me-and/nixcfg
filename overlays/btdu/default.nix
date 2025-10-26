# https://github.com/CyberShadow/btdu/issues/39
final: prev: {
  btdu = let
    version = "0.6.0-unstable-2025-04-05";
  in
    final.lib.warnIf (final.lib.versionAtLeast prev.btdu.version version) "btdu overlay is downgrading btdu"
    prev.btdu.override {
      buildDubPackage = args:
        final.buildDubPackage (args
          // {
            inherit version;

            src = args.src.override {
              rev = "af6f60594e4cfe3959beae7a6535ebdd1c091209";
              hash = "sha256-CLXzRTXRkdzaGg7qcERKNl5QtT0m08DsdHQY3RW6Yow=";
            };

            dubLock = final.lib.importJSON ./dub-lock.json;
          });
    };
}
