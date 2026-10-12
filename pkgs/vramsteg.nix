{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
}:
stdenv.mkDerivation (finalAttrs: {
  name = "vramsteg";

  # Use an unstable version as we need the fix for more modern CMake versions,
  # and the other changes since the last tagged release are trivial
  # documentation fixes.
  version = "1.1.1-unstable-2025-08-16";

  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "GothenburgBitFactory";
    repo = "vramsteg";
    rev = "e60b23a33a6d8ba55ec104b99338241ee656c7a3";
    hash = "sha256-JQFhLun2OrHWqozhfwB5vU730SlN3SFMlXwJk/pRITk=";
  };

  nativeBuildInputs = [ cmake ];

  # Installer doesn't automatically install the man page.
  postInstall = ''
    install -Dm644 doc/man/vramsteg.1 -t "$out"/share/man/man1
  '';

  # Examples should point to the executable in the output, not in a build
  # directory that's no longer extant.
  postFixup = ''
    substituteInPlace "$out"/share/doc/clog/examples/* \
        --replace-fail '../src/vramsteg' "''${out@Q}/bin/vramsteg"
  '';

  meta = {
    description = "CLI progress bar";
    homepage = "https://gothenburgbitfactory.org/vramsteg/";
    mainProgram = "vramsteg";
    license = lib.licenses.mit;
  };
})
