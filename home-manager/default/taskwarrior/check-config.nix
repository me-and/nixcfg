# Ensure the only Taskwarrior configuration that isn't declarative is the stuff
# that's supposed to be transient.
{ pkgs, ... }:
let
  checkScript = pkgs.mypkgs.writeCheckedShellScript {
    name = "check-taskwarrior-config.sh";
    runtimeInputs = [ pkgs.gnugrep ];
    text = ''
      if [[ -v TASKRC ]]; then
          config_file="$TASKRC"
      elif [[ -e "$HOME"/.taskrc ]]; then
          config_file="$HOME"/.taskrc
      elif [[ -v XDG_CONFIG_HOME ]]; then
          config_file="$XDG_CONFIG_HOME"/task/taskrc
      else
          config_file="$HOME"/.config/task/taskrc
      fi

      if grep -qEv -e '^include ' -e '^context=' -e '^news\.version=' "$config_file"; then
          echo "Unexpected content in $config_file" >&2
          exit 1
      fi
    '';
  };
in
{
  systemd.user.services.taskwarrior-config-check = {
    Unit.Description = "Check for unexpected Taskwarrior config";
    Service = {
      Type = "oneshot";
      ExecStart = checkScript;
    };
    Install.WantedBy = [ "default.target" ];
  };

  systemd.user.timers.taskwarrior-config-check = {
    Unit.Description = "Regular recheck for unexpected Taskwarrior config";
    Timer = {
      OnUnitInactiveSec = "12h";
      RandomizedDelaySec = "12h";
      AccuracySec = "12h";
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
