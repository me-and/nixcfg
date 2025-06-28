# Enable nix-index, run it automatically, and replace command-not-found with
# it.  Use a downloaded version of the database rather than building locally,
# because building locally is at best memory hungry, and at worst seems to take
# my Raspberry Pi offline due to it running out of memory.
{pkgs, ...}: let
  nix_index_dir = "/var/cache/nix-index";
in {
  programs.nix-index.enable = true;
  programs.nix-index.enableBashIntegration = true;
  programs.command-not-found.enable = false;
  environment.variables.NIX_INDEX_DATABASE = nix_index_dir;

  systemd.services.nix-index = {
    environment.NIX_INDEX_DATABASE = nix_index_dir;
    wants = ["network-online.target"];
    after = ["network-online.target"];
    serviceConfig.Type = "oneshot";
    serviceConfig.ExecStart = pkgs.writeCheckedShellScript {
      name = "update-nix-index.sh";
      text = ''
        target="$NIX_INDEX_DATABASE"/files

        arch="$(${pkgs.coreutils}/bin/uname -m)"

        # Get a temporary file name.  Fine for this to not be created
        # securely, we just want to know it's unlikely we'll get a collision
        # when we do the download.  curl's --no-clobber will make sure we
        # haven't hit an obscure window condition.
        ${pkgs.coreutils}/bin/mkdir -p "$NIX_INDEX_DATABASE"
        tmpfile="$(${pkgs.coreutils}/bin/mktemp --dry-run --tmpdir="$NIX_INDEX_DATABASE")"
        trap 'rm -f -- "$tmpfile"' EXIT

        if [[ -e "$target" ]]; then
            curl_time_args=(--time-cond "$target")
        else
            curl_time_args=()
        fi

        ${pkgs.curl}/bin/curl \
            --fail \
            --location \
            --output "$tmpfile" \
            --retry 12 \
            --no-clobber \
            --no-progress-meter \
            "''${curl_time_args[@]}" \
            https://github.com/me-and/nix-index-database/releases/latest/download/index-"$arch"-linux

        # Won't have downloaded anything if the existing file is newer than
        # the remote one
        if [[ -e "$tmpfile" ]]; then
            ${pkgs.coreutils}/bin/mv "$tmpfile" "$target"
        fi
      '';
    };
  };
  systemd.timers.nix-index = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "daily";
      AccuracySec = "24h";
      RandomizedDelaySec = "1h";
      Persistent = "true";
      RandomizedOffsetSec = "24h";
    };
  };
}
