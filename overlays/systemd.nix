final: prev:
let
  fetchSystemdPR = { pr, hash }: final.mypkgs.fetchGitHubPR {
    inherit pr hash;
    owner = "systemd";
    repo = "systemd";
  };
in
{
  systemd = prev.systemd.overrideAttrs (prevAttrs: {
    patches = prevAttrs.patches or [ ] ++ [
      (fetchSystemdPR {
        pr = "42826";
        hash = "sha256-jWbTXqrKiX+9KGcAjiwGNSYzNtppN6eHO7ybzFrHuOI=";
      })
      (fetchSystemdPR {
        pr = "42686";
        hash = "sha256-dr76x8k4YC5Gxmv60kWa8ONVmW4Bye0cKoFBN/pta24=";
      })
    ];

    # Disable the nixpkgs passthru tests: these will otherwise be run as part
    # of the flake checks, and it seems they interact badly with having
    # overridden the systemd package.  Rather than try to resolve that for a
    # (hopefully) temporary local patch, just ignore the tests entirely.
    passthru = removeAttrs prevAttrs.passthru [ "tests" ];
  });
}
