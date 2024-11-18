# https://github.com/NixOS/nixos-hardware/pull/1220
{
  config,
  lib,
  pkgs,
  ...
}: {
  options.hardware.frameworkBluetoothWorkaround = lib.mkEnableOption "the Framework workaround for Bluetooth devices on v6.11 kernels";

  config = lib.mkIf (config.hardware.frameworkBluetoothWorkaround && (config.boot.kernelPackages.kernelAtLeast "6.11") && config.boot.kernelPackages.kernelOlder "6.12") {
    systemd.services = {
      bluetooth-rfkill-suspend = {
        description = "Soft block Bluetooth on suspend/hibernate";
        before = ["sleep.target"];
        unitConfig.StopWhenUnneeded = true;
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.util-linux}/bin/rfkill block bluetooth";
          ExecStartPost = "${pkgs.coreutils}/bin/sleep 3";
          RemainAfterExit = true;
        };
        wantedBy = ["suspend.target" "hibernate.target" "suspend-then-hibernate.target"];
      };

      bluetooth-rfkill-resume = {
        description = "Unblock Bluetooth on resume";
        after = ["suspend.target" "hibernate.target" "suspend-then-hibernate.target"];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.util-linux}/bin/rfkill unblock bluetooth";
        };
        wantedBy = ["suspend.target" "hibernate.target" "suspend-then-hibernate.target"];
      };
    };
  };
}
