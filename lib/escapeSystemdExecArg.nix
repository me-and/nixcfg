# Wrap NixOS's escapeSystemdExecArg, partly so I can use it in contexts that
# dont' have access to NixOS's utils (namely Home Manager) and partly so I can
# have it quote strings that actually contain things that need quoting per
# systemd.syntax(7).
{ lib, utils }:
arg:
let
  inherit (lib)
    isString
    isInt
    isFloat
    isDerivation
    isPath
    ;
  s =
    if isPath arg then
      "${arg}"
    else if isString arg then
      arg
    else if isInt arg || isFloat arg || isDerivation arg then
      toString arg
    else
      throw "escapeSystemdExecArg only allows strings, paths, numbers and derivations";
in
if (builtins.match "[!&()*+,./0-9:<=>?@A-Z^_`a-z{|}~-]+" s == null) then
  utils.escapeSystemdExecArg s
else
  s
