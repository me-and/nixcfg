{ lib, ... }:
{
  programs.plasma.powerdevil =
    let
      commonConfig = {
        dimDisplay.enable = true;
        powerButtonAction = "showLogoutScreen";
        turnOffDisplay.idleTimeoutWhenLocked = 20;
        whenSleepingEnter = "standbyThenHibernate";
      };
    in
    {
      AC = lib.recursiveUpdate commonConfig {
        autoSuspend.action = "nothing";

        dimDisplay.idleTimeout = 120;

        turnOffDisplay.idleTimeout = 300;

        whenLaptopLidClosed = "doNothing";

        powerProfile = "performance";
      };

      battery = lib.recursiveUpdate commonConfig {
        autoSuspend.action = "sleep";
        autoSuspend.idleTimeout = 600;

        dimDisplay.idleTimeout = 120;

        turnOffDisplay.idleTimeout = 300;

        whenLaptopLidClosed = "sleep";

        powerProfile = "powerSaving";
      };

      lowBattery = lib.recursiveUpdate commonConfig {
        autoSuspend.action = "sleep";
        autoSuspend.idleTimeout = 120;

        dimDisplay.idleTimeout = 30;

        turnOffDisplay.idleTimeout = 60;

        whenLaptopLidClosed = "sleep";

        powerProfile = "powerSaving";
      };

      batteryLevels.criticalAction = "hibernate";

    };
}
