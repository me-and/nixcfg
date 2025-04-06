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
    runtimeInputs = [pkgs.coreutils];
    text = ''
      UNISON=${lib.strings.escapeShellArg "${config.home.homeDirectory}/OneDrive/Profound Decisions/.unison-state"}
      UNISONLOCALHOSTNAME=FakePDUnisonOneDriveSyncHost
      export UNISON UNISONLOCALHOSTNAME

      this_year="$(date +%Y)"

      exec ${unison}/bin/unison \
          -ignore 'Name Thumbs.db' \
          -ignore 'Name .*' \
          -ignore 'Name ~*' \
          -dontchmod -perms 0 \
          -fastcheck true \
          -ui text \
          -times \
          -root ${lib.strings.escapeShellArg "${config.home.homeDirectory}/OneDrive/Profound Decisions"} \
          -root /usr/share/gonzo \
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
    #
    # TODO This should be handled more sensibly by my Python installation
    # and/or scripts.
    home.sessionVariables.LD_LIBRARY_PATH = "${pkgs.zlib}/lib";

    home.packages = [fileServerSync unison];
  };
}
