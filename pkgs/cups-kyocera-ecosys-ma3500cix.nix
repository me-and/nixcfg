{
  fetchurl,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation {
  pname = "cups-kyocera-ecosys-ma3500cix";
  version = "9.6027";

  src = fetchurl {
    url = "https://raw.githubusercontent.com/me-and/kyocera-ppd/refs/heads/main/Kyocera%20merged%20PPD%20files/Kyocera_ECOSYS_MA3500cix.ppd";
    hash = "sha256-NjNEKgY+QRVd39lFKNJV1T1vHd/MuBmjv8cHufTqH14=";
  };
  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    install -Dm444 "$src" "$out"/share/cups/model/Kyocera/Kyocera_ECOSYS_MA3500cix.ppd
    runHook postInstall
  '';
}
