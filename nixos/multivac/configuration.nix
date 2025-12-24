{ lib, personalCfg, ... }:
{
  imports = [ personalCfg.nixosModules.wsl ];

  system.stateVersion = "25.11";

  networking.domain = "dinwoodie.org";
  networking.pd.gonzo = true;

  # TODO Fix my WSL disk to have a sensible maximum size, rather than a maximum
  # that's bigger than the containing disk, so that I can sensibly use the
  # freePercent options rather than the freeBytes options.
  nix.nhgc = {
    target.freeBytes = (1000 - 250) * 1024 * 1024 * 1024;
    trigger.freeBytes = (1000 - 350) * 1024 * 1024 * 1024;
  };

  # TODO Set this up, as I don't have any reason not to use it other than not
  # getting around to setting up the SSH keys.
  nix.nixBuildDotNet.substituter.enable = false;

  # TODO Fix up my SOPS secrets so I don't need to keep disabling this.
  nix.githubTokenFromSops = lib.warn "Need to set up github-token in SOPS" false;
}
