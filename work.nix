{ config, pkgs, ... }:
{
  config.users.users.adam.packages = [ pkgs.pn ];
}

# TODO Better modeline and/or better Vim plugins for Nix config files.
# vim: et ts=2 sw=2 autoindent ft=nix colorcolumn=80
