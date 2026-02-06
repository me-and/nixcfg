{ config, ... }:
{
  sops = {
    secrets.smtp-auth = { };
    templates.smtp-auth = {
      content = "[smtp-auth.mythic-beasts.com]:587 ${config.sops.placeholder.smtp-auth}";
      restartUnits = [ "postfix-setup.service" ];
    };
  };

  services.postfix = {
    mapFiles.sasl_passwd = config.sops.templates.smtp-auth.path;

    settings.main = {
      smtp_sasl_auth_enable = true;
      smtp_sasl_password_maps = "hash:/var/lib/postfix/conf/sasl_passwd";
      smtp_sasl_tls_security_options = "noanonymous";
      smtp_tls_security_level = "secure";
      smtp_tls_mandatory_ciphers = "high";
      smtp_tls_mandatory_protocols = ">=TLSv1.3";
      relayhost = [ "[smtp-auth.mythic-beasts.com]:587" ];
    };
  };
}
