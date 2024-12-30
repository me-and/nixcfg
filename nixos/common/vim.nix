# programs.vim.enable wasn't introduced until NixOS 24.11.
{
  lib,
  options,
  ...
}: let
  commonConfig = {
    programs.vim.defaultEditor = true;
  };

  uplevelConfig = lib.optionalAttrs (options.programs.vim ? enable) {
    warnings =
      lib.mkIf (lib.oldestSupportedReleaseIsAtLeast 2411)
      [
        ''
          Version handling in ${builtins.toString ./.}/vim.nix of
          programs.vim.enable, introduced in NixOS 24.11, can be safely
          removed.
        ''
      ];

    programs.vim.enable = true;
  };
in
  lib.mkMerge [commonConfig uplevelConfig]
