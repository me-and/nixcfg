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
  });
}
