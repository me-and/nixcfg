{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nix-update-script,
}:
buildGoModule (finalAttrs: {
  pname = "octojoin";
  version = "1.6.0-unstable-2026-07-20";

  src = fetchFromGitHub {
    owner = "matthewgall";
    repo = "octojoin";
    rev = "cedf52146d99cb1f7465296e7ad110156b018693";
    hash = "sha256-qugc4qZcp1xJIcm5WvLLn1EPBUh/jeCIxGx1nC8kIS4=";
  };

  vendorHash = "sha256-38+4AuSgfRIfV8kzAFap4v7Vq2ZgRZ05Uv/wK4FNpXE=";

  patches = [
    # https://github.com/matthewgall/octojoin/issues/13
    # This patch doesn't make the improvements I've suggested in that issue,
    # but it does at least prevent the logs being actively incorrect and
    # therefore confusing me when I've forgotten what the problem is...
    ./0001-Fix-misleading-interval-logs.patch

    # Seems the upstream code doesn't actually work anyway for joining saving
    # sessions.  Claude tells me this should, and that's good enough for my
    # purposes right now...
    #
    # TODO If this actually works in any way I'd consider appropriate to share
    # with the world, I should submit it upstream.
    ./0002-Fix-saving-session-discovery-via-backend-GraphQL.patch
  ];

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
