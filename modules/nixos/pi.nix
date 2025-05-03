{
  config,
  lib,
  ...
}: {
  options.system.isPi4 = lib.mkEnableOption "Raspberry Pi 4 configuration";

  config = lib.mkIf config.system.isPi4 {
    assertions = [
      {
        assertion = !(config.wsl.enable or false);
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
