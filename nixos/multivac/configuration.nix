{ personalCfg, ... }:
{
  imports = [ personalCfg.nixosModules.wsl ];

  system.stateVersion = "24.05";

  networking.domain = "dinwoodie.org";
  networking.pd.gonzo = true;

  nix.nhgc = {
    target.freePercent = 25;
    trigger.freePercent = 15;
  };

  # TODO Set this up, as I don't have any reason not to use it other than not
  # getting around to setting up the SSH keys.
  nix.nixBuildDotNet.substituter.enable = false;
}
