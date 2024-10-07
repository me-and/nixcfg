# https://github.com/OpenVPN/openvpn/issues/617
final: prev: {
  openvpn = prev.openvpn.overrideAttrs {
    patches = [./openvpn.diff];
  };
}
