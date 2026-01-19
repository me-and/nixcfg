# https://github.com/pycontribs/ansi2html/issues/153
final: prev: {
  ansi2html = prev.ansi2html.overrideAttrs (prevAttrs: {
    patches = (prevAttrs.patches or [ ]) ++ [ ./white.diff ];
  });
}
