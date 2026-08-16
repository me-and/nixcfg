# Prevent the systemd warnings about drkonqi-coredump-pickup.service timing
# out.
#
# TODO Report the bug upstream, ideally with a somewhat more tested test.
final: prev: {
  kdePackages = prev.kdePackages // {
    drkonqi = prev.kdePackages.drkonqi.overrideAttrs (prevAttrs: {
      patches = prevAttrs.patches or [ ] ++ [ ./0001-processor-quit-when-atLogEnd-is-reached.patch ];
    });
  };
}
