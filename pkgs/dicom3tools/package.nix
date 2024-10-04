{
  lib,
  fetchurl,
  stdenv,
  xorg,
}:
stdenv.mkDerivation rec {
  pname = "dicom3tools";
  version = "1.00.snapshot.20240914122739";
  src = fetchurl {
    url = "https://www.dclunie.com/dicom3tools/workinprogress/dicom3tools_${version}.tar.bz2";
    hash = "sha256-NYGLckMVyNmmxo4vexdVqfVaSL1izoS7n8m+1ZZodiw=";
  };
  nativeBuildInputs = [
    xorg.imake
    xorg.libX11
    xorg.libXext
    xorg.makedepend
  ];
  preBuild = ''
    makeFlagsArray+=(
        INSTALLBINDIR="''${!outputBin}/bin"
        INSTALLINCDIR="''${!outputDev}/include"
        INSTALLLIBDIR="''${!outputBin}/lib"
        INSTALLMANDIR="''${!outputMan}/share/man"
    )
  '';
  configurePhase = ''
    runHook preConfigure
    ./Configure
    imake -I./config
    runHook postConfigure
  '';
  buildFlags = ["World"];
  installFlags = ["install" "install.man"];
  #outputs = ["out" "man"];

  meta = {
    description = "Command line utilities for creating, modifying, dumping and validating files of DICOM attributes, and conversion of proprietary image formats to DICOM.";
    homepage = "https://www.dclunie.com/dicom3tools.html";
    license = lib.licenses.bsd2;
    maintainers = [lib.maintainers.me-and];
    sourceProvenance = [lib.sourceTypes.fromSource];
  };
}
