{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.kdePackages.plasma-keyboard ];
  services.displayManager.sddm = {
    settings.General.InputMethod = "qtvirtualkeyboard";
    extraPackages = [ pkgs.kdePackages.plasma-keyboard ];
  };
  systemd.services.display-manager.environment = {
    QT_IM_MODULE = "qtvirtualkeyboard";
    QT_VIRTUAL_KEYBOARD_DESKTOP_DISABLE = "0";
  };
}
