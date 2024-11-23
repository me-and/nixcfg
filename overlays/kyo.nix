# https://github.com/NixOS/nixpkgs/pull/358536
final: prev: let
  thisFile = "${builtins.toString ./.}/kyo.nix";

  basePackage =
    if prev ? cups-kyocera-3500-4500
    then
      final.lib.warn "Unnecessary use of mostStablePackage in ${thisFile}."
      prev.cups-kyocera-3500-4500
    else
      final.lib.channels.mostStablePackage {
        name = "cups-kyocera-3500-4500";
        excludeOverlays = ["kyo.nix"];
        config = {
          allowUnfreePredicate = pkg: (final.lib.getName pkg) == "cups-kyocera-3500-4500";
        };
      };

  fixedSrc = final.fetchurl {
    urls = [
      "https://www.kyoceradocumentsolutions.us/content/download-center-americas/us/drivers/drivers/MA_PA_4500ci_Linux_gz.download.gz"
      "https://web.archive.org/web/20241123173620/https://www.kyoceradocumentsolutions.us/content/download-center-americas/us/drivers/drivers/MA_PA_4500ci_Linux_gz.download.gz"
    ];
    hash = "sha256-pqBtfKiQo/+cF8fG5vsEQvr8UdxjGsSShXI+6bun03c=";
    recursiveHash = true;
    downloadToTemp = true;
    postFetch = ''
      unpackDir="$TMPDIR/unpack"
      mkdir "$unpackDir"
      cd "$unpackDir"

      mv "$downloadedFile" "$TMPDIR/source.tar.gz.gz"
      gunzip "$TMPDIR/source.tar.gz.gz"
      unpackFile "$TMPDIR/source.tar.gz"
      chmod -R +w "$unpackDir"
      mv "$unpackDir" "$out"

      # delete redundant Linux package dirs to reduce size in the Nix store; only keep Debian
      rm -r $out/{CentOS,Fedora,OpenSUSE,Redhat,Ubuntu}
    '';
  };

  checkFixSrc = src:
    if (builtins.length src.urls) == 2
    then
      final.lib.warn ''
        Unnecessary override of src in ${thisFile}: nixpkgs now has the fixed
        urls.
      ''
      src
    else fixedSrc;
in {
  cups-kyocera-3500-4500 = basePackage.overrideAttrs (prevAttrs: {
    src = checkFixSrc prevAttrs.src;
  });
}
