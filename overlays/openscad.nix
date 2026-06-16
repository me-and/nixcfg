final: prev: {
  openscad = prev.openscad.overrideAttrs (prevAttrs: {
    buildInputs = map (
      v: if v.pname == "glew" then final.glew.override { enableEGL = false; } else v
    ) prevAttrs.buildInputs;
  });
}
