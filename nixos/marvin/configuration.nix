{ nixos-hardware, personalCfg, ... }:
{
  imports = [
    nixos-hardware.nixosModules.dell-latitude-7430
    personalCfg.nixosModules.nix-builder
  ];

  system.stateVersion = "25.11";

  # Ignore the lid closing and opening: this is a laptop being used as a home
  # server, so I want to be able to close the lid and have the system keep
  # running.
  services.logind.settings.Login.HandleLidSwitch = "ignore";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.domain = "dinwoodie.org";
  networking.wireless.enable = true;

  # TODO Set up certificates to enable this.
  networking.pd.vpn = false;
  networking.pd.gonzo = false;

  programs.mosh.enable = true;

  # TODO set up keys to enable this.
  nix.nixBuildDotNet.substituter.enable = false;

  services.postfix.sendDirect = true;

  nix.gc = {
    trigger.freePercent = 15;
    target.freePercent = 25;
  };
}
