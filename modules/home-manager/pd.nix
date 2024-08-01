{
  config,
  lib,
  pkgs,
  ...
}: let
  unison = pkgs.unison.override {enableX11 = false;};

  fileServerSync = pkgs.writeCheckedShellApplication {
    name = "pd-sync-with-fileserver";
    purePath = true;
    text = ''
      exec ${unison}/bin/unison \
          -ignore 'Name Thumbs.db' \
          -ignore 'Name .*' \
          -dontchmod -perms 0 \
          -fastcheck true \
          -ui text \
          "$@" \
          ${lib.strings.escapeShellArg "${config.home.homeDirectory}/OneDrive/Documents/GOD"} \
          /usr/share/gonzo/Empire/GOD
    '';
  };
in {
  options.pd = {
    enable = lib.mkEnableOption "PD configuration";
  };

  config = lib.mkIf config.pd.enable {
    # Needed for, in particular, the Python mssql module to work, which I need
    # for accessing the PD database.
    home.sessionVariables.LD_LIBRARY_PATH = "${pkgs.zlib}/lib";

    home.packages = [fileServerSync unison];
  };
}
