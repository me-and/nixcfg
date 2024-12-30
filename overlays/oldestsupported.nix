# lib.oldestSupportedReleaseIsAtLeast was added in 24.11.  If it does exist, we
# can use it.  If it doesn't and we're checking for 24.05 or higher, it's
# clearly true.  If neither of those apply, then throw an error; it seems
# unlikely that's a scenario I'll ever need my config to support.
final: prev: {
  lib = prev.lib // {
    oldestSupportedReleaseIsAtLeast =
      if prev.lib ? oldestSupportedReleaseIsAtLeast
      then
        final.lib.warnIf (prev.lib.oldestSupportedReleaseIsAtLeast 2411)
        ''
          Patching in lib.oldestSupportedReleaseIsAtLeast in
          ${toString ./.}/oldestsupported.nix is no longer necessary.
        ''
        prev.lib.oldestSupportedReleaseIsAtLeast
      else
        ver:
        if ver >= 2405
        then true
        else throw ''
          Patched lib.oldestSupportedRelease in
          ${toString ./.}/oldestsupported.nix was never expected to handle the
          argument ${toString ver}!
        '';
    };
  }
