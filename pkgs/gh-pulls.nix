# Don't think this is popular enough to be worth trying to push to Nixpkgs
{
  lib,
  fetchFromGitHub,
  stdenvNoCC,
  makeWrapper,
  bashInteractive,
  gh,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "gh-pulls";
  version = "0-unstable-2023-03-18";

  src = fetchFromGitHub {
    owner = "AaronMoat";
    repo = "gh-pulls";
    rev = "7bd4d9b4b03d417f86a542631ee3c4964b55fb49";
    hash = "sha256-q1LXUCCNQ6ird8gYikP0m8zWqDpRVlxqbI8SmEMYyRk=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    bashInteractive
    makeWrapper
  ];

  buildInputs = [
    bashInteractive
    gh
  ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    install -D -m755 gh-pulls "$out"/bin/gh-pulls
  '';

  # Use --suffix to ensure that, if the user has a `gh` executable (e.g.
  # because they've set `programs.gh.package` in Home Manager), then that gets
  # picked up first.
  postFixup = ''
    wrapProgram "$out"/bin/gh-pulls \
      --suffix PATH : ${lib.makeBinPath finalAttrs.buildInputs}
  '';
})
