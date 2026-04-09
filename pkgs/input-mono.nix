{
  mylib,
  input-fonts,
  fetchzip,
}:
let
  input-fonts' = input-fonts.override { acceptLicense = true; };
in
input-fonts'.overrideAttrs (
  finalAttrs: prevAttrs: {
    pname = "input-mono";
    src = fetchzip {
      name = "input-mono-${finalAttrs.version}.zip";
      url = "https://input.djr.com/build/?fontSelection=fourStyleFamily&regular=InputMono-Regular&italic=InputMono-Italic&bold=InputMono-Bold&boldItalic=InputMono-BoldItalic&a=0&g=0&i=serifs&l=serifs&zero=0&asterisk=0&braces=straight&preset=default&line-height=1.2&accept=I+do&email=";
      extension = "zip";
      stripRoot = false;
      hash = "sha256-xzij76Tj7yBMK3wb04FzBJjKGxOsgFAaazj+1a2zweQ=";
    };
    meta = prevAttrs.meta // {
      license = mylib.licenses.licensedToMe;
    };
  }
)
