{
  config,
  lib,
  pkgs,
  ...
}: let
  unison = pkgs.unison.override {enableX11 = false;};

  fileServerSync = pkgs.writeCheckedShellApplication {
    name = "pd-sync-with-fileserver";
    runtimeInputs = [pkgs.coreutils];
    text = ''
      declare -r SOURCE=/usr/share/gonzo
      declare -r DEST=${lib.strings.escapeShellArg "${config.home.homeDirectory}/Documents/Profound Decisions"}

      printf -v this_year '%(%Y)T' -1

      for event_path in "$DEST"/Event/*; do
          if [[ "$event_path" != "$DEST"/Event/*"$this_year"* ]]; then
              rsp='unset'
              while [[ "''${rsp,}" != y && "''${rsp,}" != n  && "$rsp" != ''' ]]; do
                  read -r -p "Delete old event directory ''${event_path@Q}? [y/N] " rsp
              done
              if [[ "$rsp" = y ]]; then
                  rm -r "$event_path"
              fi
          fi
      done

      exec ${unison}/bin/unison \
          -ignore 'Name Thumbs.db' \
          -ignore 'Name .*' \
          -ignore 'Name ~*' \
          -fat \
          -fastcheck true \
          -ui text \
          -times \
          -root "$SOURCE" \
          -root "$DEST" \
          -mountpoint Empire/GOD \
          -mountpoint Event \
          -mountpoint 'IT/Front End' \
          -mountpoint Site/Signs \
          -path Empire/GOD \
          -path 'IT/Front End/Empire.mdb' \
          -path 'IT/Front End/Backups' \
          -ignore 'Path IT/Front End/Backups/*' \
          -ignorenot 'Path IT/Front End/Backups/*Empire*.mdb' \
          -path IT/Fonts \
          -path 'IT/Software/Printer Drivers' \
          -path Artwork/Logos \
          -path Empire/Art/Font \
          -path Event \
          -ignore 'Path Event/*' \
          -ignorenot "Path Event/*$this_year*" \
          -path Site/Signs \
          -path 'Unknown Worlds/art' \
          -path 'Weapon Check' \
          "$@"
    '';
  };
in {
  options.pd = {
    enable = lib.mkEnableOption "PD configuration";
  };

  config = lib.mkIf config.pd.enable {
    # Needed for, in particular, the Python mssql module to work, which I need
    # for accessing the PD database.
    #
    # TODO This should be handled more sensibly by my Python installation
    # and/or scripts.
    home.sessionVariables.LD_LIBRARY_PATH = "${pkgs.zlib}/lib";

    home.packages = [fileServerSync unison];
  };
}
