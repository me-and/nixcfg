# Copilot CLI on NixOS

This environment runs NixOS. When an executable cannot be found, use Nix to run
tools without installing them globally.

## Finding files

Prefer repository search for project files, or a narrowly scoped `find` command
for files outside the repository.  Never use `find` with broad directories,
e.g. `find /`, `find /nix/store` or `find "$HOME"`, as this will be slow and
inefficient.

For finding files that might be in a public OSS package, use `nix-locate`, e.g.
`nix-locate sysexits.h` will produce output like the following:

```
...
man-pages.man                                     2,022 r /nix/store/b78d5cgwzjd6kb42k1m76na3i8hgc68q-man-pages-6.18-man/share/man/man3head/sysexits.h.3head.gz
llvmPackages.libc-full.dev                          569 r /nix/store/cy7fvcsmimnwgbp8sf8xr0293y48hwv3-libc-21.1.8-dev/include/sysexits.h
glibc.dev                                         5,232 r /nix/store/29isvm6vfq10c528i31igdiy3fnvjcm3-glibc-2.42-67-dev/include/sysexits.h
...
```

This indicates you could find `sysexits.h` by running `nix build nixpkgs#glibc.dev`
and looking in `result-dev/include/sysexits.h`.  Add `--no-link --print-out-paths`
to skip creating a symlink and get the destination path instead.

`nix-locate` and `nix-locate-bin` use an index based on files in binary caches,
not the local system.

## Finding Executables

Use the `nix-locate-bin` utility to find which package contains a command:

```bash
nix-locate-bin pdfunite
# Output: poppler-utils.out
```

`nix-locate-bin` is a simplified interface to the `nix-locate` utility.

Then run the command with `nix shell` or `nix run` (see below).

## Running Commands

For a single invocation of the main executable in a package, use `nix run` with
the package name:

```bash
nix run nixpkgs#pandoc -- --version
nix run nixpkgs#jq -- '.key' file.json
nix run nixpkgs#ffmpeg -- -i input.mp4 output.mp3
```

If a package has multiple executables, use `nix shell` to allow specifying the
executable to run.

```bash
nix shell nixpkgs#poppler-utils --command pdfunite source1.pdf source2.pdf
```

Also use `nix shell` for an environment with multiple packages:

```bash
nix shell nixpkgs#python3 nixpkgs#nodejs --command python3 script.py
```

These commands all run in subshells, so changes to the environment won't
persist.  To run multiple commands with the same environment, chain them
together with a short script or Bash command:

```bash
nix shell nixpkgs#python3 nixpkgs#poppler-utils --command bash -c 'python3 script.py && pdfseparate output.pdf'
```

## Python specifics

If you need specific Python packages to be available, use `python3.withPackages`:

```bash
nix shell --impure --expr 'with import (builtins.getFlake "nixpkgs") { }; python3.withPackages (ps: [ ps.lxml ps.requests ])' --command python3 -c 'import lxml; ...'
```

For a new project, use the current supported Python version as determined with
`nix eval --raw nixpkgs#python3.version`.

`uv` or `pip`-installed executables (e.g. `ruff`, `mypy`) can fail with "Could
not start dynamically linked executable".  Workarounds include:

- For tools invocable as a module (e.g. mypy): `uv run python -m mypy` works.
- For tools that don't support `python -m` well (e.g. ruff, since `python -m ruff`
  hits the same broken binary path): use `nix run nixpkgs#ruff -- check .`
  instead.  Be aware this may be a different version to the version pinned in a
  package.
- A `uv` project's CLI entry point should be invoked with `uv run
  <entry-point>...`, not by changing the PATH.
