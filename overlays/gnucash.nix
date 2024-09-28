# https://github.com/NixOS/nixpkgs/pull/345187
final: prev: {
  gnucash = prev.gnucash.overrideAttrs (finalattrs: prevattrs: {
    postFixup = prevattrs.postFixup + ''
      if [[ -x $out/share/applications/gnucash.desktop ]]; then
          printf 'Redundant overlay in %s\n' ${final.lib.escapeShellArg (builtins.toString ./gnucash.nix)} >&2
          exit 1
      fi
      chmod +x $out/share/applications/gnucash.desktop
    '';
  });
}
