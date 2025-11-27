# Enable the tzupdate service, but also account for mullvad potentially being
# installed, in which case the tzupdate service should be run wrapped with
# mullvad-exclude.
{
  config,
  options,
  lib,
  pkgs,
  ...
}:
let
  mullvadCfg = config.services.mullvad-vpn;
  opts = options.services.tzupdate;
in
{
  warnings = lib.optional (mullvadCfg.enable && !mullvadCfg.enableExcludeWrapper) ''
    You have set services.mullvad-vpn.enable = true and
    services.mullvad-vpn.enableExcludeWrapper = false, while importing your
    tzupdate module.  If you use a VPN in this scenario, tzupdate is likely to
    detect your location as being the exit point of your VPN connection, which
    is probably not what you want!
  '';

  services.tzupdate = {
    enable = true;
    package =
      let
        wrappedScript = pkgs.mypkgs.writeCheckedShellApplication {
          name = "tzupdate";
          text = ''
            ${mullvadCfg.package}/bin/mullvad-exclude ${lib.getExe opts.package.default} "$@"
          '';
        };
      in
      lib.mkIf (mullvadCfg.enable && mullvadCfg.enableExcludeWrapper) wrappedScript;
  };
}
