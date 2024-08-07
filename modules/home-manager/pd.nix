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
      UNISON=${lib.strings.escapeShellArg "${config.home.homeDirectory}/OneDrive/Profound Decisions/.unison-state"}
      export UNISON

      this_year="$(date +%Y)"

      exec ${unison}/bin/unison \
          -ignore 'Name Thumbs.db' \
          -ignore 'Name .*' \
          -ignore 'Name ~$*' \
          -ignore 'Name ~*.idlk' \
          -dontchmod -perms 0 \
          -fastcheck true \
          -ui text \
          -times \
          -root ${lib.strings.escapeShellArg "${config.home.homeDirectory}/OneDrive/Profound Decisions"} \
          -root /usr/share/gonzo \
          -path Empire/GOD \
          -path 'IT/Front End/Empire.mdb' \
          -path IT/Fonts \
          -path 'IT/Software/Printer Drivers' \
          -path Artwork/Logos \
          -path Empire/Art/Font \
          -path Event \
          -ignore 'Path Event/*' \
          -ignorenot "Path Event/* - $this_year" \
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
    home.sessionVariables.LD_LIBRARY_PATH = "${pkgs.zlib}/lib";

    home.packages = [fileServerSync unison];
  };
}
