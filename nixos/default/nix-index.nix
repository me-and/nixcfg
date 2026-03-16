{ config, pkgs, ... }:
{
  programs.nix-index.enable = true;
  environment.variables.NIX_INDEX_DATABASE = "/var/cache/nix-index";

  systemd.services.nix-index = {
    environment = { inherit (config.environment.variables) NIX_INDEX_DATABASE; };
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    path = [
      config.programs.nix-index.package
      pkgs.jq
    ];
    serviceConfig.Type = "oneshot";
    serviceConfig.ExecStart = pkgs.mypkgs.writeCheckedShellScript {
      name = "update-nix-index.sh";
      text = ''
        shopt -s nullglob

        declare -ir EX_OSFILE=72

        target="$NIX_INDEX_DATABASE"/files
        store_cache="$NIX_INDEX_DATABASE"/nixpkgs_path

        populate_nixpkgs_path () {
            # This assumes using flakes, nixpkgs' path being set in the default
            # flake registry location, and the flake registry being in the
            # format I expect.  That's good enough for me for now, but
            # decidedly fragile.  Although using `nix eval` to get the path
            # seemed even more fragile!
            nixpkgs_path="$(jq -r </etc/nix/registry.json '.flakes[] | select(.exact and .from == {id: "nixpkgs", type: "indirect"} and .to.type == "path") | .to.path')"
            if [[ -z "$nixpkgs_path" ]]; then
                echo 'could not find nixpkgs path in /etc/nix/registry.json' >&2
                exit "$EX_OSFILE"
            elif [[ ! -e "$nixpkgs_path" ]]; then
                echo "nixpkgs path $nixpkgs_path does not exist" >&2
                exit "$EX_OSFILE"
            fi
        }

        do_cache_update () {
            mkdir -p -- "$NIX_INDEX_DATABASE"

            populate_nixpkgs_path
            printf '%s' "$nixpkgs_path" >"$store_cache"

            # By default, nix-index starts writing the new database over the
            # top of the existing one, which means there's a window where there
            # is no valid database.  Avoid that by putting the new index in a
            # temporary directory then moving it into place.
            rm -rf -- "$NIX_INDEX_DATABASE"/tmp.nix-index.*
            tmpdir="$(mktemp --dir "$NIX_INDEX_DATABASE"/tmp.nix-index.XXXXX)"

            # nix-index likes to use carriage return in its output.  That's not
            # very useful when logs are going to the system journal, as it
            # results in the output mostly saying "[... blob data]".  Use `tr`
            # to prevent that.  See https://www.shellcheck.net/wiki/SC2312 for
            # more info on the exec approach being taken.
            # shellcheck disable=SC2312
            exec {stderr_wrangling_fd}> >(tr '\r' '\n' >&2)
            stderr_wrangling_pid="$!"
            nix-index --db "$tmpdir" --nixpkgs "$nixpkgs_path" 2>&"$stderr_wrangling_fd"
            exec {stderr_wrangling_fd}>&-
            wait "$stderr_wrangling_pid"

            # The `mv` plus `rm --dir` combine to make sure the output file we
            # expect to exist does exist, and nothing else is present.
            mv -- "$tmpdir"/files "$NIX_INDEX_DATABASE"/files
            rm --dir -- "$tmpdir"
        }

        if [[ ! -e "$target" ]]; then
            # There is no cache, so we need to create one.
            do_cache_update
        elif [[ "$store_cache" -nt "$target" ]]; then
            # The nix-index cache hasn't been updated since we updated the path
            # to the store cache, so it must be out of date.  Presumably a
            # previous run failed.
            do_cache_update
        else
            populate_nixpkgs_path
            if [[ -e "$store_cache" ]]; then
                cached_nixpkgs_path="$(<"$store_cache")"
            else
                cached_nixpkgs_path=""
            fi

            if [[ "$nixpkgs_path" != "$cached_nixpkgs_path" ]]; then
                # The current nix-index cache was generated for a different
                # nixpkgs, so we need to update it.
                do_cache_update
            fi
        fi
      '';
    };
  };
  systemd.timers.nix-index = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      AccuracySec = "24h";
      RandomizedDelaySec = "1h";
      Persistent = "true";
      RandomizedOffsetSec = "24h";
    };
  };
}
