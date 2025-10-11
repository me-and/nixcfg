{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Home Manager checks there is only a single primary email account, so we
  # don't need to repeat that check here.
  primaryEmailAccount = lib.lists.findSingle (acc: acc.primary) null null (
    builtins.attrValues config.accounts.email.accounts
  );
  primaryEmailAddress = primaryEmailAccount.address;
in
{
  imports = [
    (lib.mkRemovedOptionModule [
      "accounts"
      "email"
      "forwardLocal"
    ] "If it is useful, consider returning the config from your Git history!")
  ];

  home.activation.dotForward = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    email_address=${lib.escapeShellArg primaryEmailAddress}
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
}
