{
  lib,
  substCheckedShellApplication,
  runtimeShell,
  jq,
  flock,
  gh,
}:
substCheckedShellApplication {
  name = "gh-nixpkgs-rand";
  src = ./gh-nixpkgs-rand.sh;
  replacements =
    let
      runtimeInputs = [
        jq
        flock
        gh
      ];
    in
    {
      "#!/usr/bin/env bash\n" = ''
        #!${runtimeShell}
        export PATH="''${PATH:+"$PATH":}"${lib.escapeShellArg (lib.makeBinPath runtimeInputs)}
      '';
      "./updates.jq" = ./updates.jq;
      "./display.jq" = ./display.jq;
    };
}
# Home Manager's programs.gh.extensions expects every extension package to have
# a pname attribute.  This isn't the case for our
# `substCheckedShellApplication`, nor is it the case for upstream's
# `writeShellApplication`, so I think this is a Home Manager bug.  Work around
# it by providing a pname.
#
# TODO: Report this to Home Manager.  I think the fix is simply changing `name
# = p.pname` to `name = p.pname or p.name` in modules/programs/gh.nix.
// {
  pname = "gh-nixpkgs-rand";
}
