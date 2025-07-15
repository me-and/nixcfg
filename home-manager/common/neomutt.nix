# TODO The default config includes 'set delete = yes', which is an opinionated
# default that it should be possible to override.
{
  accounts.email.accounts.main.neomutt = {
    enable = true;
    extraConfig = ''
      set reverse_name = yes
      unset reverse_realname
      alternates '[@\.]dinwoodie\.org$' '^adam@profounddecisions\.co\.uk$' '^(adamdinwoodie|gamma3000|knightley\.nightly|sorrowfulsnail)@(gmail|googlemail)\.com$' '^adam@tastycake\.net$' '^adam\.dinwoodie@worc\.oxon\.org$'
      unset trash
    '';
  };

  programs.neomutt = {
    settings.use_envelope_from = "yes";
  };
}
