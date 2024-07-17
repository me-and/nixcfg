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
  doInstallCheck ? true,
  # Whether to include the user environment in Homeshick's path.  Set this to
  # true for a more pure program, leave it as false to allow Homeshick to find
  # programs like Git authentication helpers in the user PATH.
  purePath ? false,
  # Extra packages added as runtime dependencies.  Use this in particular if
  # you want to use purePath but rely on other packages such as GitHub CLI as
  # Git authentication helpers.
  extraRuntimeDeps ? [],
}: let
  version = "2.0.1";
  runtimeDeps = [git coreutils findutils gnused] ++ extraRuntimeDeps;

  # Homeshick tests have effectively pinned their Bats libraries to specific
  # versions, and also expect to find the files in specific locations, as
  # defined in its test/get_bats_libs.sh file.  Respect that paradigm and use
  # the same library versions, rather than using Nixpkgs' bats.withLibraries to
  # install what may be the wrong version and will definitely still need
  # linking to the place Homeshick's tests expect to find them.
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
    installPhase =
      ''
        runHook preInstall

        mkdir $out
        cp -r *.md LICENSE bin completions homeshick.sh homeshick.fish lib $out
      ''
      # Only copy the test directories if we'll need them for the install test
      # phase.
      + lib.optionalString doInstallCheck ''
        cp -r test $out
      ''
      + ''

        runHook postInstall
      '';

    # Wrap homeshick so it has the expected paths.  Can't wrap homeshick.sh or
    # homeshick.fish as they need to edit the caller's environment, so instead
    # rewrite them to something that has the correct directory for the location
    # of the homeshick script.
    postFixup = let
      pathArgs =
        if purePath
        then "--set PATH ${lib.makeBinPath runtimeDeps}"
        else "--prefix PATH : ${lib.makeBinPath runtimeDeps}";
    in ''
      wrapProgram $out/bin/homeshick \
          ${pathArgs} \
          --set-default HOMESHICK_DIR $out

      ${gnused}/bin/sed -i \
          's!$HOME/\.homesick/repos/homeshick!'"$out"'!' \
          $out/homeshick.sh $out/homeshick.fish
    '';

    # Run the tests as install tests, as they usefully test the wrapper
    # handling of HOMESHICK_DIR and PATH.
    inherit doInstallCheck;
    installCheckInputs = [bats git bash expect fish dash];
    installCheckPhase = ''
      runHook preInstallCheck

      cd $out

      # Emulate the Bats library building that test/get_bats_libs.sh does.
      mkdir -p test/bats/lib
      ln -sfn ${batsSupport} test/bats/lib/support
      ln -sfn ${batsAssert} test/bats/lib/assert
      ln -sfn ${batsFile} test/bats/lib/file
      bats "$PWD/test/suites"

      # Entirely done with the test directory now.
      rm -rf test

      runHook postInstallCheck
    '';

    meta = {
      description = "Git dotfiles synchronizer written in Bash";
      longDescription = ''
        A Git dotfiles synchronising and management tool similar to Homesick,
        but written in Bash rather than Ruby.
      '';
      homepage = "https://github.com/andsens/homeshick";
      license = lib.licenses.mit;
      maintainers = [lib.maintainers.me-and];
      mainProgram = "homeshick";
    };
  }
