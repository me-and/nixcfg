{
  lib,
  config,
  options,
  pkgs,
  ...
}: let
  # Units for setting up loopback devices.
  loopDeviceConfig = let
    commonConfig = {
      unitConfig.RequiresMountsFor = ["%f" "%t"];
      environment = {
        DEVICE_FILE = "%t/%n.device";
      };
      serviceConfig.Type = "oneshot";
      serviceConfig.ExecStartPre = ["${pkgs.coreutils}/bin/rm -f \${DEVICE_FILE}"];
      serviceConfig.StandardOutput = "file:%t/%n.device";
      serviceConfig.StandardError = "journal";
      serviceConfig.ExecStop = pkgs.writeCheckedShellScript {
        name = "setup-loop-device-stop";
        text = ''
          device="$(<"$DEVICE_FILE")"
          ${pkgs.util-linux}/bin/losetup -d "$device"
        '';
      };
      serviceConfig.ExecStopPost = "${pkgs.coreutils}/bin/rm -f \${DEVICE_FILE}";
      serviceConfig.RemainAfterExit = true;
    };
  in {
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
      serviceConfig.ExecStart = let
        reportScript = pkgs.writeCheckedShellScript {
          name = "mailstate.sh";
          bashOptions = ["errexit" "nounset"];
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
                ${pkgs.colourmail}/bin/colourmail \
                    -s "Unit $unit $unit_state on $shorthost" \
                    -r "$from" \
                    -- "$user"
          '';
        };
      in "${reportScript} %i %u %l %H";
    };
  };

  shellcheckConfig = {
    systemd.enableStrictShellChecks = true;
    systemd.services.linger-users.enableStrictShellChecks = false; # https://github.com/NixOS/nixpkgs/pull/363209
    systemd.services.cups.enableStrictShellChecks = false; # TODO fix
  };

  # Gate this on whether wireless networking is enabled at all, as otherwise
  # this config would create a wpa_supplicant.service systemd unit that
  # wouldn't otherwise exist.
  shellcheckWpaSupplicantConfig =
    lib.mkIf
    (
      (options.systemd ? enableStrictShellChecks)
      && config.networking.wireless.enable
    )
    {
      warnings =
        lib.mkIf (lib.oldestSupportedReleaseIsAtLeast 2411)
        [
          ''
            Version handling in ${builtins.toString ./.}/systemd.nix of
            systemd.enableStrictShellChecks, introduced in NixOS 24.11, can be
            safely removed.
          ''
        ];

      systemd.services.wpa_supplicant.enableStrictShellChecks = false; # TODO fix
    };

  # Add support for RandomizedOffsetSec= in timer units.
  packageConfig = {
    systemd.package = pkgs.systemd.overrideAttrs (prevAttrs: {
      patches =
        prevAttrs.patches
        ++ map pkgs.fetchpatch [
          # https://github.com/systemd/systemd/pull/36437
          {
            url = "https://github.com/systemd/systemd/commit/9a0749c82b313d4abd31171beb7cca48bd56f19b.patch";
            hash = "sha256-Qjcaxs7oPvQokTtCOUHHEtZZnkakFEZw6pZ15L6G0Fk=";
          }

          # https://github.com/systemd/systemd/pull/37981
          {
            url = "https://github.com/systemd/systemd/commit/c6bb846c04fe326c3b5c2f31ae6eace8b2ce7153.patch";
            hash = "sha256-gmPVPdjCXUGuOu2SDqd2lo45kzHaOvNLL7NlebPHnPc=";
          }
        ];
    });
  };
in
  lib.mkMerge [
    loopDeviceConfig
    mailStateConfig
    shellcheckConfig
    shellcheckWpaSupplicantConfig
    packageConfig
  ]
