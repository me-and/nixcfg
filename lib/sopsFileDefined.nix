{ lib }:
{ options, key }:
let
  defaultPrio = (lib.mkOptionDefault null).priority;
in
options.sops.defaultSopsFile.isDefined || ((options.sops.secrets.valueMeta.attrs."${key}".configuration.options.sopsFile.highestPrio or defaultPrio) < defaultPrio)
