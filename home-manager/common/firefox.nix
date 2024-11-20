{
  config,
  lib,
  options,
  ...
}: let
  cfg = config.programs.firefox;

  mainConfig = {
    programs.firefox = {
      profiles.default = {
        containersForce = true;
        containers = {
          TopCashback = {
            color = "green";
            icon = "cart";
            id = 1;
          };
          Quidco = {
            color = "turquoise";
            icon = "cart";
            id = 2;
          };
          "Complete Savings" = {
            color = "blue";
            icon = "cart";
            id = 3;
          };
          iMutual = {
            color = "red";
            icon = "cart";
            id = 4;
          };
          "Perks at Work" = {
            color = "orange";
            icon = "cart";
            id = 5;
          };
          Unite = {
            color = "red";
            icon = "briefcase";
            id = 6;
          };
        };
      };
    };
  };

  languagePacks = ["en-GB"];

  # Handle the case where language pack config is not available.
  # https://github.com/nix-community/home-manager/commit/304a011325b7ac7b8c9950333cd215a7aa146b0e
  homeManagerHasLanguagePackOption = options.programs.firefox ? languagePacks;
  languageConfig =
    if homeManagerHasLanguagePackOption
    then {
      warnings = [
        ''
          Redundant handling of programs.firefox.languagePacks present in
          ${builtins.toString ./.}/firefox.nix.  You can significantly simplify
          that file if you're sure this configuration will no longer be used
          anywhere that doesn't support programs.firefox.languagePacks config.
        ''
      ];

      programs.firefox.languagePacks = languagePacks;
    }
    else {
      assertions = [
        {
          assertion = cfg.package != null;
          message = ''
            Trying to set language pack configuration, but that requires
            programs.firefox.package to be non-null.
          '';
        }
      ];

      programs.firefox.policies = {
        ExtensionSettings = lib.listToAttrs (map (lang:
          lib.nameValuePair "langpack-${lang}@firefox.mozilla.org" {
            installation_mode = "normal_installed";
            install_url = "https://releases.mozilla.org/pub/firefox/releases/${cfg.package.version}/linux-x86_64/xpi/${lang}.xpi";
          })
        languagePacks);
      };
    };
in
  lib.mkMerge [mainConfig languageConfig]
