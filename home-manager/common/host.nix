{lib, ...}: {
  options.home.hostName = lib.mkOption {
    description = "System host name, mostly for use by other options.";
    type = lib.types.strMatching "^$|^[[:alnum:]]([[:alnum:]_-]{0,61}[[:alnum:]])?$";
  };
}
