{
  pkgs,
  lib,
  llm-agents,
  ...
}:
{
  programs.github-copilot-cli = {
    enable = true;
    package =
      # https://github.com/numtide/llm-agents.nix/issues/8175
      # https://github.com/numtide/llm-agents.nix/pull/8174
      llm-agents.packages."${pkgs.stdenv.hostPlatform.system}".copilot-cli.overrideAttrs (prevAttrs: {
        preInstall = ''
          makeWrapper_type="$(type -t makeWrapper)"

          if [[ "$makeWrapper_type" != function ]]; then
              nixErrorLog "Unexpected type of makeWrapper"
              nixErrorLog "Expected function"
              nixErrorLog "Got $makeWrapper_type"
              exit 1
          fi

          makeWrapper_defn="$(declare -fp makeWrapper)"

          # Wrap the makeWrapper function with a version that will suppress any
          # `--set SSL_CERT_DIR <val>` arguments.
          eval "''${makeWrapper_defn/#makeWrapper /makeWrapperInner }"
          makeWrapper () {
              local -a args=()
              local seen_ssl_cert_dir=
              while (( $# > 0 )); do
                  if (( $# >= 3 )); then
                      if [[ "$1" = --set && "$2" = SSL_CERT_DIR ]]; then
                          shift 3
                      else
                          args+=("$1")
                          shift
                      fi
                  else
                      args+=("$@")
                      break
                  fi
              done

              makeWrapperInner "''${args[@]}"
          }
        ''
        + prevAttrs.preInstall or "";

        postInstall = prevAttrs.postInstall or "" + ''
          # Reset the definition of makeWrapper
          eval "$makeWrapper_defn"
        '';
      });

    lspServers.nix = {
      command = lib.getExe pkgs.nil;
      fileExtensions.".nix" = "nix";
    };

    agents.nix-regression-investigator = ./nix-regression-investigator.agent.md;
  };
}
