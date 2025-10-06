{
  config,
  lib,
  ...
}: {
  options.system.isPi4 = lib.mkEnableOption "Raspberry Pi 4 configuration";

  config = lib.mkIf config.system.isPi4 {
    # Working bootloader configuration for the Pi.
    boot.loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
  };
}
