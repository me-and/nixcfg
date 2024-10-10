{
  dpkg,
  fetchurl,
  stdenv,
  runCommand,
}:
stdenv.mkDerivation rec {
  pname = "nordvpn";
  version = "3.19.0";
  src = fetchurl {
    url = "https://repo.nordvpn.com/deb/nordvpn/debian/pool/main/nordvpn_3.19.0_amd64.deb";
    hash = "sha256-vsl+uneuDEuUmlvRnMILUwRuRkRXVtk5a7OcQ9tYbpY=";
  };
  unpackCmd = ''
    ${dpkg}/bin/dpkg -x "$curSrc" deb
  '';
}
