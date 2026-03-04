{ config, lib, pkgs, modulesPath, personalCfg, ... }:
{
  imports = [
    "${modulesPath}/virtualisation/qemu-vm.nix"
    personalCfg.nixosModules.minimal
  ];

  system.stateVersion = "25.11";

  nixpkgs.hostPlatform = "x86_64-linux";

  services.getty.autologinUser = config.users.me;

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

  programs.bash.logout = "sudo systemctl poweroff";

  services.avahi.enable = lib.mkForce false;
  programs.screen.enable = lib.mkForce false;
  services.locate.enable = lib.mkForce false;
  services.openssh.enable = false;
  documentation.man.cache.enable = lib.mkForce false;
  services.postfix.enable = lib.mkForce false;
  programs.nix-index.enable = lib.mkForce false;
  systemd.timers.nix-index.enable = false;
  home-manager.users.root = lib.mkForce ({ osConfig, ... }: { home.stateVersion = osConfig.system.stateVersio; });
}
