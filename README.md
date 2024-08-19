nixcfg
======

This repository stores my [NixOS][] and [Home Manager][] configurations.

[NixOS]: https://nixos.org/
[Home Manager]: https://github.com/nix-community/home-manager

Layout
------

This is documented here primarily for my own benefit!  It's also a goal, not
where I'm currently at...

### `configuration.nix` and `home.nix`

These are the root files for NixOS and Home Manager builds respectively.  They
should define the configuration I want that's common to everywhere I'm using
NixOS or Home Manager.

### `pkgs`

This directory vaguely emulates the [Nixpkgs `by-name`][by-name] directory
structure.  It should contain a folder for each package, with the folder
containing a `package.nix` file that can be called using
[`pkgs.callPackage`][callPackage].  Other associated files (e.g. patch files)
can live in the same directory.

It should be possible to build any package with the following call:

    nix-build ./pkgs -A package-name

This will automatically use whatever `<nixpkgs>` repository that `nix-build`
finds, with the [overlays][] from the `overlays` directory.  If you want to use
a different `<nixpkgs>` repository, either provide the path using the `-I`
argument to `nix-build`, or by specifying `--attr pkgsPath path/to/repo`.  You
_can_ specify a `pkgs` attribute instead, but packages can rely on overlays in
the `overlays` directory, so you may need to do more awkward wrangling to make
sure the appropriate overlays are in place.

Packages are built and tested by GitHub Actions.

[by-name]: https://github.com/NixOS/nixpkgs/tree/master/pkgs/by-name
[callPackage]: https://nixos.org/guides/nix-pills/13-callpackage-design-pattern
[overlays]: https://nixos.org/manual/nixpkgs/stable/#sec-overlays-definition

### `modules`

This directory should contain modules that can be imported by Home Manager,
NixOS, or both, and the module file should be in the appropriate subdirectory.
All the modules should be imported unconditionally in the appropriate
circumstances by mentioning them in the relevant `default.nix` files.

Files in this directory should be ones that, at least in principle, could be
taken upstream or used by other people (although there's no requirement that
they not have dependencies on other parts of this repository, so someone else
actually taking them may need to also take several other parts of the
repository).  In particular, where they define configuration, rather than
merely defining
and implementing configuration _options_, that should be because they're
defining sensible defaults that others might use.  Configuration that's likely
to be specific to me should go in either `configuration.nix`, `home.nix` or
under the `config` subdirectory.

### `overlays`

Files in this directory should be automatically included when building a
package in this directory or when building a NixOS or Home Manager system based
on the `configuration.nix` and `home.nix` files.  Additionally, Home Manager
will install the overlays directory so that otherwise-unrelated invocations of
`nix-build` and similar will automatically include these overlays.

I'm using overlays in the following circumstances:

-   To incorporate all the packages in the `pkgs` directory (see
    `overlays/pkgs.nix`).
-   Where I want to change an existing package in Nixpkgs.  Ideally every such
    change either has a specific reason why it can't be taken upstream, or is
    in the process of being taken upstream.
-   Where I want to add something to Nixpkgs that isn't a _package_, e.g. a
    build helper.  Packages in the `pkgs` directory should build using
    `pkgs.callPackage` without any additional arguments.

### `lib`

Files in this directory are ones that I want to call explicitly when I need
them for some specific purpose; there is no requirement that they have a
standard interface.

### `config`

TODO

### `local-config.nix`

This file will be imported by both `configuration.nix` and `home.nix` if it
exists.  In most circumstances, I'd prefer it not to exist, but there are two
scenarios where I'm using it:

-   Configuration that used to use this model but hasn't yet been migrated to
    have the configuration checked into the `config` directory with appropriate
    "is this the right system" tests for whether to use it.
-   Configuration that uses imports, such as importing hardware modules from
    the NixOS/nixos-hardware repository, because "is this the right system"
    tests only happen after the Nix module evaluation has finished importing
    modules.

### `secrets` and `local-config`

TODO

Format
------

Nix files should follow the [Alejandra][] formatting style; this is checked
using the `style.sh` script, which is run automatically by GitHub Actions.
Having tried a selection of different formatters, Alejandra's style was the one
I ended up objecting to least.

[Alejandra]: https://kamadorueda.com/alejandra/
