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

      # TODO
      # https://nix-community.github.io/home-manager/options.xhtml#opt-programs.firefox.profiles._name_.extensions
      # search = ...

      # TODO
      # https://nix-community.github.io/home-manager/options.xhtml#opt-programs.firefox.profiles._name_.settings
      # settings = ...
    };

    # TODO
    # https://nix-community.github.io/home-manager/options.xhtml#opt-programs.firefox.policies
    # policies = ...
  };
}
