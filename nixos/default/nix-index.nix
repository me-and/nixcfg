{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkMerge [
  { programs.nix-index.enable = lib.mkDefault true; }

  (lib.mkIf config.programs.nix-index.enable {
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
      serviceConfig.Nice = 19;
      serviceConfig.IOSchedulingClass = "idle";
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

          # nix-index likes to use carriage return in its output.  That's not
          # very useful when logs are going to the system journal, as it
          # results in the output mostly saying "[... blob data]".  Use `tr`
          # to prevent that.  The "generating index" part is also very noisy,
          # so only output one line of that output every ten seconds.
          #
          # Use stdbuf to ensure lines are written to the journal promptly.
          process_stderr () {
              SECONDS=10
              stdbuf -oL tr '\r' '\n' |
                  while read -r line; do
                      if [[ "$line" = '+ generating index: '* ]]; then
                          if (( SECONDS >= 10 )); then
                              SECONDS=0
                              printf '%s\n' "$line"
                          fi
                      else
                          printf '%s\n' "$line"
                      fi
                  done
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

              # Exec trick based on https://www.shellcheck.net/wiki/SC2312:
              # create a new file descriptor that points to a background
              # process running the process_stderr function and sending its
              # output to our current stderr.  Then send stderr from nix-index
              # to that file descriptor; running nix-index directly means if it
              # produces a non-zero exit code, that'll be caught by the script
              # directly.  Once nix-index finishes, close the file descriptor
              # and wait for the process to end; the wait command will give us
              # the exit code from that background process.
              #
              # shellcheck disable=SC2312
              exec {stderr_wrangling_fd}> >(process_stderr >&2)
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
  })
]
