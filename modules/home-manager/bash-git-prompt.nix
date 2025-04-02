{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.bash-git-prompt;
in {
  options.programs.bash-git-prompt = {
    enable = lib.mkEnableOption "bash-git-prompt";
    theme = lib.mkOption {
      description = ''
        Theme to use.  Set as `null` to avoid specifying a theme, or "Custom"
        to use a custom theme.
      '';
      default =
        if cfg.customThemeFile == null
        then null
        else "Custom";
      example = "Solarized";
      defaultText = lib.literalMD "If `customTheme` or `customThemeFile` are defined, then `\"Custom\"`, else `null`.";
      type = with lib.types; nullOr str;
    };
    customTheme = lib.mkOption {
      description = ''
        Custom theme script.
      '';
      default = null;
      type = with lib.types; nullOr lines;
    };
    customThemeFile = lib.mkOption {
      description = ''
        Path to a custom theme script.  Overrides `customTheme` if both are
        set.
      '';
      default =
        if cfg.customTheme == null
        then null
        else pkgs.writeText "git-prompt-colors.sh" cfg.customTheme;
      type = with lib.types; nullOr path;
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.programs.bash.enable;
        message = "bash-git-prompt requires bash";
      }
    ];

    programs.bash.initExtra =
      lib.optionalString (cfg.customThemeFile != null) ''
        GIT_PROMPT_THEME_FILE=${cfg.customThemeFile}
      ''
      + lib.optionalString (cfg.theme != null) ''
        GIT_PROMPT_THEME=${lib.escapeShellArg cfg.theme}
      ''
      + ''
        . ${pkgs.bash-git-prompt}/gitprompt.sh
      '';
  };
}
