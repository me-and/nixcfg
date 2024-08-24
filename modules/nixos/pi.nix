{
  config,
  lib,
  ...
}: {
  options.system.isPi4 = lib.mkEnableOption "Raspberry Pi 4 configuration";

  config = lib.mkIf config.system.isPi4 {
    assertions = [
      {
        assertion = ! config.system.isWsl;
        message = "Cannot be both WSL and a Raspberry Pi!";
      }
    ];

    # Want the Raspberry Pi hardware overlay.
    nix.channels = {
      nixos-hardware = "https://github.com/NixOS/nixos-hardware/archive/master.tar.gz";
    };

    # Working bootloader configuration for the Pi.
    boot.loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
  };
}
