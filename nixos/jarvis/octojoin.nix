{ config, ... }:
{
  sops = {
    secrets."octopus/api-key" = { };
    secrets."octopus/account-number" = { };
    # This doesn't handle the YAML escaping.  That _should_ be fine...
    templates."octojoin.yaml".content = ''
      account_id: ${config.sops.placeholder."octopus/account-number"}
      api_key: ${config.sops.placeholder."octopus/api-key"}
    '';
  };

  services.octojoin = {
    enable = true;
    configFile = config.sops.templates."octojoin.yaml".path;
  };
}
