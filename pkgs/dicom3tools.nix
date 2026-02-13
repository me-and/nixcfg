# I'd originally planned to make this available in nixpkgs, but per the below
# links, the person responsible for the project is deeply reluctant for some of
# the binaries to be distributed if they're not compiled with the user's own
# allocated UID.  Some of the binaries are clearly safe, and the key ones I
# cared about for converting DICOM images to formats ImageMagick can work with
# are ones I'd have thought were safe, but those aren't distributed in the
# maintainer's binaries for Windows or Mac, and (unlike some binaries) don't
# compile to byte-identical executables when compiled with different UIDs.
#
# Maybe I could work out a way to do it safely, and/or just do what Debian did
# and only provide binaries that don't include the ones I've been interested
# in, but neither of those are very satisfying.  For now this package lives in
# my local repository for the rare occasions I want it and for reference for
# anyone who manages to stumble across it.
#
# References:
# https://groups.google.com/g/comp.protocols.dicom/c/cZ8mYtQOXGM
# https://sources.debian.org/src/dicom3tools/1.00~20140902075059-1/debian/README.Debian/
{
  lib,
  fetchurl,
  stdenv,
  imake,
  libX11,
  libXext,
  makedepend,
  # If you have your own UIDs allocated, this is the place to define them, e.g.
  # by adding `"-DDefaultUIDRoot=1.2.840.99999"`.
  imakeConfigurationArgs ? [ ],
}:
stdenv.mkDerivation rec {
  pname = "dicom3tools";
  version = "1.00.snapshot.20240914122739";
  src = fetchurl {
    url = "https://www.dclunie.com/dicom3tools/workinprogress/dicom3tools_${version}.tar.bz2";
    hash = "sha256-NYGLckMVyNmmxo4vexdVqfVaSL1izoS7n8m+1ZZodiw=";
  };
  nativeBuildInputs = [
    imake
    libX11
    libXext
    makedepend
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
    imake -I./config ${lib.escapeShellArgs imakeConfigurationArgs}
    runHook postConfigure
  '';
  buildFlags = [ "World" ];
  installFlags = [
    "install"
    "install.man"
  ];

  meta = {
    description = "Command line utilities for creating, modifying, dumping and validating files of DICOM attributes, and conversion of proprietary image formats to DICOM.";
    homepage = "https://www.dclunie.com/dicom3tools.html";
    # Non-standard BSD-3 based license.  TODO Is there a better way to define
    # this?  What do other packages with sui generis licenses do?
    license = {
      shortName = "dicom3tools";
      fullName = "dicom3tools license";
      redistributable = true;
      deprecated = false;
      url = "https://www.dclunie.com/dicom3tools/COPYRIGHT";
    };
    maintainers = [ lib.maintainers.me-and ];
    sourceProvenance = [ lib.sourceTypes.fromSource ];
  };
}
