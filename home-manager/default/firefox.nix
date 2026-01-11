{
  config,
  lib,
  options,
  ...
}:
{
  programs.firefox = {
    languagePacks = [ "en-GB" ];

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

      # TODO
      # https://nix-community.github.io/home-manager/options.xhtml#opt-programs.firefox.profiles._name_.extensions
      # extensions = ...
      # settings.extensions.autoDisableScopes = 0;

      # Check Firefox's generated config using `nix run nixpkgs#dejsonlz4 --
      # .mozilla/firefox/default/search.json.mozlz4` (replacing "default" with
      # a different profile name if required).
      search = rec {
        force = true;
        engines = {
          # Not sure why Kagi has such a terrible default name, but I expect
          # the extension usage is part of it.  At some point I should set up
          # my Home Manager configuration to set up extensions per the above
          # TODO, as I've no idea how badly wrong this'll go if I don't have
          # the extensiom already installed...
          "search@kagi.comdefault" = {
            name = "Kagi";
            loadPath = "[addon]search@kagi.com";
            iconMapObj = {
              "16" = "moz-extension://69a63ed5-4470-4d5d-a65d-c7f7fc50b3b9/icons/icon_16px.png";
              "32" = "moz-extension://69a63ed5-4470-4d5d-a65d-c7f7fc50b3b9/icons/icon_32px.png";
              "48" = "moz-extension://69a63ed5-4470-4d5d-a65d-c7f7fc50b3b9/icons/favicon-48.png";
              "180" = "moz-extension://69a63ed5-4470-4d5d-a65d-c7f7fc50b3b9/icons/icon_180px.png";
            };
            urls = [
              {
                template = "https://kagi.com/search?q={searchTerms}";
              }
              {
                template = "https://kagisuggest.com/api/autosuggest?q={searchTerms}";
                type = "application/x-suggestions+json";
              }
            ];
          };

          wikipedia.metaData.alias = "w";
        };
        default = builtins.head order;
        order = [
          "search@kagi.comdefault"
          "wikipedia"
          "google"
        ];
      };

      # TODO
      # https://nix-community.github.io/home-manager/options.xhtml#opt-programs.firefox.profiles._name_.settings
      # settings = ...
    };

    # TODO
    # https://nix-community.github.io/home-manager/options.xhtml#opt-programs.firefox.policies
    # policies = ...
  };
}
