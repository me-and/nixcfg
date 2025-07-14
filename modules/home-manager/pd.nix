{
  config,
  lib,
  pkgs,
  ...
}: {
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
  };
}
