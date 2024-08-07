{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.accounts.email;

  # Home Manager checks there is only a single primary email account, so we
  # don't need to repeat that check here.
  primaryEmailAccount =
    lib.lists.findSingle (acc: acc.primary) null null
    (builtins.attrValues cfg.accounts);
  primaryEmailAddress = primaryEmailAccount.address;
in {
  options.accounts.email.forwardLocal = {
    enable = lib.mkOption {
      description = ''
        Whether to automatically forward local emails to another account.  This
        sets the .forward file in your home directory, and requires an
        appropriately configured mail transfer agent.
      '';
      type = lib.types.bool;
      default = false;
    };
    target = lib.mkOption {
      description = "Email address to forward local emails on to.";
      type = lib.types.str;
      default = primaryEmailAddress;
      example = "adam@example.org";
    };
  };

  config = lib.mkIf cfg.forwardLocal.enable {
    home.activation.dotForward = lib.hm.dag.entryAfter ["writeBoundary"] ''
      email_address=${lib.escapeShellArg cfg.forwardLocal.target}
      forward_file=${lib.escapeShellArg config.home.homeDirectory}/.forward

      if [[ -e "$forward_file" ]]; then
          # The .forward file already exists.  Ensure it's a normal file:
          # symlinks don't work with, for example, postfix, and more esoteric
          # options like directories are definitely not going to work.
          # Assuming it's a normal file, check the contents.
          if [[ -f "$forward_file" ]] &&
              ${pkgs.diffutils}/bin/diff -b \
                  "$forward_file" \
                  - <<<"$email_address"
          then
              # Existing file has the right config.
              verboseEcho "~/.forward already contains $email_address"
          else
              errorEcho "Unexpected content in ~/.forward"
              errorEcho "Either manually correct or remove the file"
              exit 1
          fi
      else
          run printf '%s' "$email_address" | run --quiet tee "$forward_file"
      fi
    '';
  };
}
