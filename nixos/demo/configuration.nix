{ config, pkgs, modulesPath, ... }:
{
  imports = [ "${modulesPath}/virtualisation/qemu-vm.nix" ];

  system.stateVersion = "25.11";

  #boot.loader.systemd-boot.enable = true;
  #boot.loader.efi.canTouchEfiVariables = true;

  nixpkgs.hostPlatform = "x86_64-linux";

  users.users = {
    "${config.users.me}".hashedPassword = "";
    root.hashedPassword = "";
  };
  services.getty.autologinUser = config.users.me;
  security.sudo.wheelNeedsPassword = false;

  nix.gc.store.enable = false;
  nix.nixBuildDotNet.substituter.enable = false;
  nix.githubTokenFromSops = false;

  virtualisation.graphics = false;
  virtualisation.qemu.options = [ "-serial mon:stdio" ];

  # https://github.com/nix-community/nixos-generators/blob/8946737ff703382fda7623b9fab071d037e897d5/formats/vm-nogui.nix
  environment =
    let resize = pkgs.writeScriptBin "resize" ''
      if [[ -e /dev/tty ]]; then
          old="$(stty -g)"
          stty raw -echo min 0 time 5
          printf '\033[18t' >/dev/tty
          IFS=';t' read -r _ rows cols _ </dev/tty
          stty "$old"
          stty cols "$cols" rows "$rows"
      fi
    '';
  in {
    systemPackages = [ resize ];
    loginShellInit = "${resize}/bin/resize";
  };
}
