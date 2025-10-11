# https://github.com/OpenVPN/openvpn/issues/617
final: prev: {
  openvpn = prev.openvpn.overrideAttrs (prevAttrs: {
    patches = (prevAttrs.patches or [ ]) ++ [ ./openvpn.diff ];
  });
}
