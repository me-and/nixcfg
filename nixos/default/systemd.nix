{ lib, pkgs, ... }:
let
  packageConfig = {
    systemd.package = pkgs.systemd.overrideAttrs (
      prevAttrs:
      let
        fetchSystemdPatch =
          args:
          pkgs.mypkgs.fetchGitHubPatch (
            {
              owner = "systemd";
              repo = "systemd";
            }
            // args
          );

        # Handle RuntimeDirectory values with specifiers that resolve to
        # contain backslashes.
        #
        # https://github.com/systemd/systemd/issues/41853
        # https://github.com/systemd/systemd/pull/42686
        escapePatchOne = fetchSystemdPatch {
          commit = "e82f85ea3428bae471abd55b8a70ac97306926ef";
          hash = "sha256-Nhld7+XXRdrfj17tOKPha1Avz9ULjv65xdOfLeSKSgY=";
        };
        escapePatchTwo = fetchSystemdPatch {
          commit = "385ba9f766d50027dcf1e0114e12da5f6fd17b97";
          hash = "sha256-hQstQmCHR1u0OQ4FfBg9BE9Lns+ueD//4O+EWfoZENM=";
        };

        # Handle timers jumping backwards more sensibly.  Not a fix I'm
        # particularly interested in for myself, but it introduces changes that
        # are necessary for timerOffsetPatch to apply.
        #
        # https://github.com/systemd/systemd/issues/6036
        # https://github.com/systemd/systemd/pull/43116
        timerClampPatch = fetchSystemdPatch {
          commit = "34c60f113e78db7554c5521e856265feb53f1096";
          hash = "sha256-yYP4lUE0fAXoxWjGErGRhMDtAbVT0MSmJonNnD9clCI=";
        };

        # Avoid unexpected timer delays with RandomizedOffsetSec + Persistent
        # timers.
        #
        # https://github.com/systemd/systemd/issues/42337
        # https://github.com/systemd/systemd/pull/42826
        timerOffsetPatch = fetchSystemdPatch {
          commit = "7b761dba0f5848cf7097804235750764d42dfcf1";
          hash = "sha256-Nh/8GrLI1x/ruiFUR3C6iVao4tD+iCl+YOiZrEDCNVg=";
        };
      in

      {
        patches = prevAttrs.patches or [ ] ++ [
          escapePatchOne
          escapePatchTwo
          timerClampPatch
          timerOffsetPatch
        ];

        # Expose the patches so I can more easily check them.
        passthru =
          assert !(prevAttrs.passthru ? myPatches);
          prevAttrs.passthru
          // {
            myPatches = {
              inherit
                escapePatchOne
                escapePatchTwo
                timerClampPatch
                timerOffsetPatch
                ;
            };
          };
      }
    );
  };

  # Units for setting up loopback devices.
  loopDeviceConfig =
    let
      commonConfig = {
        unitConfig.RequiresMountsFor = [
          "%f"
          "%t"
        ];
        environment = {
          DEVICE_FILE = "%t/%n.device";
        };
        serviceConfig.Type = "oneshot";
        serviceConfig.ExecStartPre = [ "${pkgs.coreutils}/bin/rm -f \${DEVICE_FILE}" ];
        serviceConfig.StandardOutput = "file:%t/%n.device";
        serviceConfig.StandardError = "journal";
        serviceConfig.ExecStop = pkgs.mypkgs.writeCheckedShellScript {
          name = "setup-loop-device-stop";
          text = ''
            device="$(<"$DEVICE_FILE")"
            ${pkgs.util-linux}/bin/losetup -d "$device"
          '';
        };
        serviceConfig.ExecStopPost = "${pkgs.coreutils}/bin/rm -f \${DEVICE_FILE}";
        serviceConfig.RemainAfterExit = true;
      };
    in
    {
      systemd.services = {
        "setup-loop-device-ro@" = lib.recursiveUpdate commonConfig {
          description = "Set up %f as a read-only loop device";
          serviceConfig.ExecStart = "${pkgs.util-linux}/bin/losetup -fPr --show %f";
        };
        "setup-loop-device-rw@" = lib.recursiveUpdate commonConfig {
          description = "Set up %f as a read-write loop device";
          serviceConfig.ExecStart = "${pkgs.util-linux}/bin/losetup -fP --show %f";
        };
      };
    };

  # Unit for sending emails reporting the state of another unit.
  mailStateConfig = {
    systemd.services."mail-state@" = {
      description = "Unit %i state report";
      serviceConfig.Type = "oneshot";
      serviceConfig.RuntimeDirectory = "mail-state@%i";
      serviceConfig.ExecStart =
        let
          reportScript = pkgs.mypkgs.writeCheckedShellScript {
            name = "mailstate.sh";
            bashOptions = [
              "errexit"
              "nounset"
            ];
            text = ''
              unit="$1"
              user="$2"
              shorthost="$3"
              longhost="$4"

              if [[ "$user" = root ]]; then
                  systemctl () { ${pkgs.systemd}/bin/systemctl --system "$@"; }
                  from="\"systemd on $shorthost\" <''${user}@''${longhost}>"
              else
                  systemctl () { ${pkgs.systemd}/bin/systemctl --user "$@"; }
                  from="\"''${user}'s systemd on $shorthost\" <''${user}@''${longhost}>"
              fi

              unit_state="$(systemctl show -PActiveState "$unit")"

              # shellcheck disable=SC2312 # systemctl expected to return non-zero
              SYSTEMD_COLORS=True SYSTEMD_URLIFY=False \
                  systemctl status "$unit" |
                  ${pkgs.mypkgs.colourmail}/bin/colourmail \
                      -s "Unit $unit $unit_state on $shorthost" \
                      -r "$from" \
                      -- "$user"
            '';
          };
        in
        "${reportScript} %i %u %l %H";
    };
  };

  shellcheckConfig = {
    systemd.enableStrictShellChecks = true;
    systemd.services.linger-users.enableStrictShellChecks = false; # https://github.com/NixOS/nixpkgs/pull/363209
    systemd.services.cups.enableStrictShellChecks = false; # TODO fix
  };
in
{
  options.systemd.services = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        serviceConfig.SyslogIdentifier = lib.mkDefault "%N";
      }
    );
  };

  config = lib.mkMerge [
    packageConfig
    loopDeviceConfig
    mailStateConfig
    shellcheckConfig
  ];
}
