# Copilot Instructions

## Build, Test, and Lint Commands

```bash
# Format all Nix files
nix fmt

# Check formatting without writing (CI mode)
nix fmt -- --ci

# Evaluate all flake outputs without building
nix flake check --no-build --all-systems --keep-going

# Build all checks for the current system (packages + NixOS + home-manager configs)
nix run .#nix-run-available-checks

# Build a specific NixOS system  (hosts: hex, jarvis, marvin, multivac)
nix build .#nixosConfigurations.<host>.config.system.build.toplevel

# Build a specific home-manager config  (format: <user>@<host>)
nix build .#homeConfigurations."<user>@<host>".activationPackage

# Build a specific package  (systems: x86_64-linux, aarch64-linux)
nix build .#packages.<system>.<package-name>

# Evaluate a single check (faster than building everything)
nix build .#checks.<system>.<check-name>
```

## Architecture

This is a multi-host NixOS + Home Manager flake configuration for 4 machines:

| Host | System | Role |
|------|--------|------|
| `hex` | x86_64-linux | Framework laptop, KDE Plasma desktop |
| `jarvis` | aarch64-linux | ARM server (email, taskwarrior) |
| `marvin` | x86_64-linux | Dell laptop / media server |
| `multivac` | x86_64-linux | NixOS-WSL instance on Windows 11 |

### Module Auto-Discovery

The key architectural pattern is **auto-discovery via `lib/`**. Neither `nixos/` nor `home-manager/` modules are explicitly imported; instead `dirmodules` and `dirfiles` scan directories at flake evaluation time:

```nix
nixosModules = dirmodules { dir = ./nixos; };
homeModules  = dirmodules { dir = ./home-manager; };
```

A module in `nixos/<hostname>/` is automatically included in that host's config. A module in `nixos/default/` is included in **all** hosts. The same applies to `home-manager/`.

### Module Loading for Each Host

For each host (`name`) the flake assembles modules from:
- `nixosModules.default` → `nixos/default/`
- `nixosModules.<name>` → `nixos/<name>/`
- Same pattern from `private` flake input

For home-manager, modules are resolved from:
- `homeModules.default`, `homeModules.<username>`, `homeModules.<hostname>`, `homeModules.<username>@<hostname>`

### Special Args Available in Modules

NixOS modules receive: `nixos-hardware`, `disko`, `sops-nix`, `wsl`, `self`, `mylib`, `personalCfg`, `homeConfig`

Home Manager modules receive: `plasma-manager`, `sops-nix`, `user-systemd-config`, `mylib`, `personalCfg`, `osConfig`

### Nixpkgs Config and Overlays

`config.nix` sets `allowlistedLicenses` using `mylib.licenses.licensedToMe`. Overlays from `self`, `private`, and `sops-nix` are composed and applied to every `pkgs` instance. Overlays in `overlays/` can optionally accept flake inputs as their first argument — the flake inspects `functionArgs` to pass only what each overlay requests.

### Checks

`checks` is a union of:
1. All packages (from `pkgs/`)
2. `nixosConfigurations` build toplevels (per-system)
3. `homeConfigurations` activation packages (per-system)
4. Extra checks from `checks/` (overlay compilation tests, etc.)

## Key Conventions

### Adding a New Module

- **Shared across all hosts**: add a `.nix` file to `nixos/default/` or `home-manager/default/`
- **Host-specific**: add a `.nix` file to `nixos/<hostname>/` or `home-manager/<hostname>/`
- **Optional/task-specific module**: add to the `nixos/` or `home-manager/` root (not inside a host or `default/` subdirectory), then import explicitly via `personalCfg.nixosModules.<name>` or `personalCfg.homeModules.<name>` in the relevant host config

Task-specific modules can be a single file (e.g. `nixos/games.nix`) or a directory with a `default.nix` (e.g. `nixos/games/default.nix`).

No `imports = [...]` needed for auto-discovered paths — files are picked up automatically.

### Custom Packages

Add packages under `pkgs/`. They are exposed as `legacyPackages.<system>` and `packages.<system>`, and automatically included in `checks`. Use `writeCheckedShellApplication` / `writeCheckedShellScript` (from `mypkgs`) for shell scripts — these run shellcheck.

### Related Repositories

- **`nixcfg-private`** (`github:me-and/nixcfg-private`) is pulled in as the `private` flake input. Configuration that shouldn't be public (e.g. email setup, personal network details) belongs there, not here.
- **`nixcfg-alianza`** is a separate flake owned by Alianza that pulls *this* repo in as an input. Work/employer-specific configuration belongs there. Nothing Alianza-specific should be added to this public repository.
- **`user-systemd-config`** (`github:me-and/user-systemd-config`) is pulled in as a non-flake input. It contains legacy static files that haven't yet been ported to Nix config. Nothing should be added there, but some of its files are used by this repo's configurations.

See the "Secrets and privacy" section of `README.md` for the full breakdown of what belongs where.

### Secrets (SOPS)

Secrets are managed with `sops-nix`. Secrets files live in the private flake input (`github:me-and/nixcfg-private`).

### `lib/` Functions

| Function | Use |
|----------|-----|
| `dirmodules { dir }` | Load a directory as NixOS/HM modules by filename |
| `dirfiles { dir; excludes? }` | Load `.nix` files into an attrset |
| `unionOfDisjointAttrsList` | Merge attrsets, error on conflicts |
| `escapeSystemdExecArg(s)` | Escape args for systemd `ExecStart` |
| `escapeSystemdPath/String` | Escape paths/strings for systemd units |
| `removeAll` | Remove all occurrences of a value from a list |

### Code Style

- Nix formatting is enforced by `nixfmt-tree` (run via `nix fmt`); CI will fail on unformatted files
- NixOS and Home Manager modules take their arguments as a multi-line attrset (with `...` where needed); packages use `callPackage` and do not include `...`
- `lib.mkDefault` for values that hosts can override
- `lib.mkIf cfg.enable { ... }` pattern for conditional config blocks
- `inherit` used extensively to reduce repetition
