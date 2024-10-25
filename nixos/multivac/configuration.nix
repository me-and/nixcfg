let
  # Avoid using lib for this, so it can be safely used with imports.
  fileIfExtant = file:
    if builtins.pathExists file
    then [file]
    else [];
in {
  imports = [
    <nixos-wsl/modules>
    ../common
  ]
  ++ fileIfExtant ./local-config.nix;

  system.stateVersion = "24.05";
  wsl.enable = true;
  networking.hostName = "multivac";
  networking.domain = "dinwoodie.org";

  networking.accessPD = true;

  services.postfix = {
    enable = true;
    relayHost = "smtp.tastycake.net";
    relayPort = 587;
  };
}
