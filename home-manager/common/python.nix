{
  config,
  lib,
  pkgs,
  ...
}:
let
  # TODO Fix up these dependencies to be a bit more idiomatic rather than just
  # affecting the general Python installation.
  python = pkgs.python3.withPackages (pp: [
    pp.requests # Needed for petition signing script
    (pkgs.mypkgs.asmodeus.override { python3Packages = pp; })
  ]);
in
{
  imports = [
    (lib.mkRemovedOptionModule [ "programs" "mypy" ] "")
    (lib.mkRemovedOptionModule [ "pd" ] "")
  ];

  home.packages = [ python ];

  # Needed for, in particular, the Python mssql module to work, which I need
  # for accessing the PD database.
  #
  # TODO This should be handled more sensibly by my Python installation
  # and/or scripts.
  home.sessionVariables.LD_LIBRARY_PATH = lib.makeLibraryPath [ pkgs.zlib ];
}
