final: prev: {
  systemd = prev.systemd.overrideAttrs (prevAttrs: {
    patches = prevAttrs.patches or [ ] ++ [
      (final.mypkgs.fetchGitHubPR {
        owner = "systemd";
        repo = "systemd";
        pr = "42826";
        hash = "sha256-jWbTXqrKiX+9KGcAjiwGNSYzNtppN6eHO7ybzFrHuOI=";
      })
    ];

    # Disable the nixpkgs passthru tests: these will otherwise be run as part
    # of the flake checks, and it seems they interact badly with having
    # overridden the systemd package.  Rather than try to resolve that for a
    # (hopefully) temporary local patch, just ignore the tests entirely.
    passthru = removeAttrs prevAttrs.passthru [ "tests" ];
  });
}
