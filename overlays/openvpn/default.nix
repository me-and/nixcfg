final: prev: {
  openvpn = prev.openvpn.overrideAttrs {
    patches = [./openvpn.diff];
  };
}
