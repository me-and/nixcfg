# nixcfg

This repository holds the main [NixOS][] and [Home Manager][] configurations I use.  It's very unlikely to be useful to anyone else as-is, but feel free to use as much of it as you'd like.

[NixOS]: https://nixos.org
[Home Manager]: https://home-manager.dev/

Be warned: this config gets used as much as a playground and a learning opportunity as it does anything else.  As a result, a lot of approaches may be unnecessarily complex.  Sometimes my fun isn't finding a simple solution, but learning how to do things the complex way, so I know the possibilities when complexity is required.

## Structure

### Flake outputs

*   `lib`: a collection of Nix functions building on Nixpkgs' `lib`.  No derivations.
*   `legacyPackages`: the same sort of stuff that exists in Nixpkgs' `legacyPackages`: derivations and functions that produce derivations.
*   `packages`: all the top-level derivations in `legacyPackages`.
*   `nixosConfigurations`: my NixOS system configurations, with `<hostname>` keys.
*   `homeConfigurations`: my Home Manager configurations, with `<username>@<hostname>` keys (just because that's how Home Manager runs things by default).
*   `nixosModules`:
    *   `default`: my common NixOS configuration.  This is a mix of configuration I always want, and configuration controlled by options.
    *   `<hostname>`: the modules that define system-specific configurarion.
    *   `<taskname>`: modules for importing when I want a system to perform a particular task.
*   `homeModules`:
    *   `default`: my common Home Manager configuration.  This is a mix of configuration I always want, and configuration controlled by options.
    *   `<username>`: the modules that define configuation I want anywhere I'm using a given username.
    *   `<hostname>`: the modules that define system-specific configurarion.
    *   `<username>@<hostname>`: the modules that define configuration specific to a username and host combination.
    *   `<taskname>`: modules for importing when I want a system to perform a particular task.
*   `overlays`: [Nixpkgs overlays][].  Mostly these change derivations to add patches or fixes I want, but `overlays.pkgs` adds the contents of `legacyPackages` as `pkgs.mypkgs`, and the contents of `lib` as `pkgs.mylib`.  Note the flake output is an attribute set, with the overlay functions as values, but most inputs that look for overlays expect a list of overlay functions.
*   `checks`: the union of `packages`, `nixosConfigurations` and `homeConfigurations`, filtered to the appropriate architecture.
*   `formatter`: [`pkgs.nixfmt-tree`][nixfmt-tree].

[Nixpkgs overlays]: https://nixos.org/manual/nixpkgs/stable/#chap-overlays
[nixfmt-tree]: https://search.nixos.org/packages?channel=unstable&show=nixfmt-tree

### File and directory structure

*   `flake.nix`: sets up everything in the "Flake outputs" section above.
*   `lib`: contains definitions for my library functions.  This is imported using Nixpkgs' `lib.packagesFromDirectoryRecursive`, prepopulated with Nixpkgs' `lib`.
*   `overlays`: contains all my Nixpkgs overlays.  Files ending in `.nix`, and folders containing a `default.nix`, will both be picked up automatically by my packages and flakes.
*   `default.nix`: sets up my packages to build based on the `pkgs` directory.
*   `pkgs`: contains definitions for Nix derivations.  This is imported using Nixpkgs' `lib.packagesFromDirectoryRecursive`, prepopulated with Nixpkgs' `pkgs` with my overlays already applied, plus the other packages in the set.  *Should* usefully evaluate as a stand-alone file without using flakes, although that's not something I test regularly.
*   `config.nix`: this is my common Nixpkgs config.
*   `nixos`:
    *   `default`: this contains a series of NixOS modules that is common to all my NixOS configs.
    *   `<hostname>`: this contains the configuration for each system's NixOS configuration.
    *   `<taskname>`: this contains configuration that can be imported for performing some specific task.
*   `home-manager`:
    *   `default`: this contains a series of Home Manager modules that is common to all my Home Manager configs.
    *   `<username>`, `<hostname>` or `<username>@hostname`: this contains the configuration for each system's Home Manager configuration, set in `home.nix`.
    *   `<taskname>`: this contains configuration that can be imported for performing some specific task.

## Secrets and privacy

I'm broadly grouping my data into four categories: public, private, work and secret:

Type | Description | Data management
-----|-------------|----------------
Public | Data such as this repository, where I'm anywhere between "indifferent" and "actively keen" about it being available to the general public. | Data can go in public repositories and the Nix store.  Nix config generally belongs in this repository.
Private | Data that I'm comfortable being known by anywhere between a small and large number of people, but not the world at large, such as email address configuration, medical notes, or my terrible music tastes. | Data can go in private repositories and the Nix store, at least as long as that store isn't publicly available.  Nix config generally belongs in the private GitHub repository that is pulled in as a flake by this repository.
Work | Data that belongs to my employer, generally because I wrote it to help me do my job while working for them. | As required by my employer.  Nix config generally belongs in employer-controlled code management that pulls in this repository as a flake input.
Secret | Passwords, credentials, keys, ... | Should only appear in any version control or Nix store if encrypted; should only appear on a filesystem if encrypted or, if the balance of risks allows it, with locked-down file permissions.
