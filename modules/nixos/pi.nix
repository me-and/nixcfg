{
  config,
  lib,
  ...
}: {
  options.system.isPi4 = lib.mkEnableOption "Raspberry Pi 4 configuration";

  config = {
    assertions = [
      {
        assertion = config.system.isPi4 -> (! config.system.isWsl);
        message = "Cannot be both WSL and a Raspberry Pi!";
      }
    ];

    # Working bootloader configuration for the Pi.
    boot.loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
  };
}
