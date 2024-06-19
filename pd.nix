{ lib, pkgs, ... }:
{
  options.pd = {
    enable = lib.mkEnableOption "PD configuration";
  };

  # Needed for, in particular, the Python mssql module to work, which I need
  # for accessing the PD database.
  config.home.sessionVariables = lib.mkIf config.pd.enable {
    LD_LIBRARY_PATH = "${pkgs.zlib}/lib";
  };
}
