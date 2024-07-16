{
  lib,
  fetchFromGitHub,
  stdenvNoCC,
  git,
  makeWrapper,
  bats,
  coreutils,
  bash,
  findutils,
  expect,
  gnused,
  fish,
  dash,
}: let
  version = "2.0.1";
  runtimeDeps = [git coreutils findutils gnused];

  batsSupport = fetchFromGitHub {
    owner = "bats-core";
    repo = "bats-support";
    rev = "v0.3.0";
    hash = "sha256-4N7XJS5XOKxMCXNC7ef9halhRpg79kUqDuRnKcrxoeo=";
  };
  batsAssert = fetchFromGitHub {
    owner = "bats-core";
    repo = "bats-assert";
    rev = "v2.0.0";
    hash = "sha256-whSbAj8Xmnqclf78dYcjf1oq099ePtn4XX9TUJ9AlyQ=";
  };
  batsFile = fetchFromGitHub {
    owner = "bats-core";
    repo = "bats-file";
    rev = "v0.3.0";
    hash = "sha256-3xevy0QpwNZrEe+2IJq58tKyxQzYx8cz6dD2nz7fYUM=";
  };
in
  stdenvNoCC.mkDerivation {
    pname = "homeshick";
    inherit version;
    src = fetchFromGitHub {
      owner = "andsens";
      repo = "homeshick";
      rev = "v${version}";
      hash = "sha256-LsFtuQ2PNGQuxj3WDzR2wG7fadIsqJ/q0nRjUxteT5I=";
    };
    nativeBuildInputs = [makeWrapper];
    dontConfigure = true;
    dontBuild = true;

    # TODO Install completion files.  See e.g.
    # https://github.com/moaxcp/nur/blob/master/pkgs/micronaut-cli/default.nix
    # with installShellFiles and installShellCompletion
    installPhase = ''
      runHook preInstall

      mkdir $out
      cp -r * $out

      runHook postInstall
    '';

    # Wrap homeshick so it has the expected paths.  Can't wrap homeshick.sh or
    # homeshick.fish as they need to edit the caller's environment, so instead
    # rewrite them to something that has the correct directory for the location
    # of the homeshick script.
    postFixup = ''
      wrapProgram $out/bin/homeshick \
          --set PATH ${lib.makeBinPath runtimeDeps} \
          --set-default HOMESHICK_DIR $out

      ${gnused}/bin/sed -i \
          's!$HOME/\.homesick/repos/homeshick!'"$out"'!' \
          homeshick.sh homeshick.fish
    '';

    # Run the tests as install tests, as they usefully test the wrapper
    # handling of HOMESHICK_DIR and PATH.
    doInstallCheck = true;
    installCheckInputs = [bats git bash expect fish dash];
    installCheckPhase = ''
      runHook preInstallCheck

      cd $out
      mkdir -p test/bats/lib
      ln -sfn ${batsSupport} test/bats/lib/support
      ln -sfn ${batsAssert} test/bats/lib/assert
      ln -sfn ${batsFile} test/bats/lib/file
      bats "$PWD/test/suites"

      # Entirely done with the test directory now.
      rm -rf test

      runHook postInstallCheck
    '';
  }
