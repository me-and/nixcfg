{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nix-update-script,
}:
buildGoModule (finalAttrs: {
  pname = "octojoin";
  version = "1.6.0";

  src = fetchFromGitHub {
    owner = "matthewgall";
    repo = "octojoin";
    tag = "v${finalAttrs.version}";
    hash = "sha256-Jb4AbUnjoLWw8a6NzmCz5evLnB42yso5dziWNfGnoYA=";
  };

  vendorHash = "sha256-g+yaVIx4jxpAQ/+WrGKxhVeliYx7nLQe/zsGpxV4Fn4=";

  # https://github.com/matthewgall/octojoin/issues/13
  # This patch doesn't make the improvements I've suggested in that issue, but
  # it does at least prevent the logs being actively incorrect and therefore
  # confusing me when I've forgotten what the problem is...
  patches = [ ./check-interval-log.patch ];

  # Tests require a writable home directory.
  preCheck = ''
    HOME="$(mktemp --directory --tmpdir)"
    export HOME
  '';

  passthru.updateScript = nix-update-script { extraArgs = [ "--flake" ]; };

  meta = {
    description = "Utility for monitoring Octopus Energy UK accounts";
    longDescription = ''
      A comprehensive Go application that monitors Octopus Energy (UK) saving
      sessions and free electricity periods, with automatic session joining and
      a real-time web dashboard.
    '';
    homepage = "https://github.com/matthewgall/octojoin";
    donationPage = "https://github.com/sponsors/matthewgall";
    license = lib.licenses.asl20;
    mainProgram = "octojoin";
  };
})
