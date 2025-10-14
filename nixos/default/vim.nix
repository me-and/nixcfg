# programs.vim.enable wasn't introduced until NixOS 24.11.
{
  lib,
  options,
  ...
}:
{
  programs.vim = {
    enable = true;
    defaultEditor = true;
  };
}
