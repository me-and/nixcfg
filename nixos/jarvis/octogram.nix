{ config, octogram, ... }:
{
  imports = [ octogram.nixosModules.default ];

  sops = {
    secrets."octopus/api-key" = { };
    secrets."octopus/account-number" = { };
    secrets.octogram-bot-token = { };
    secrets.telegram-chat-id = { };
    templates."octogram.conf".content = ''
      [octopus]
      api_key = ${config.sops.placeholder."octopus/api-key"}
      account_number = ${config.sops.placeholder."octopus/account-number"}

      [telegram]
      bot_token = ${config.sops.placeholder.octogram-bot-token}
      chat_id = ${config.sops.placeholder.telegram-chat-id}

      [settings]
      price_threshold_p = 0
    '';
  };

  services.octogram = {
    enable = true;
    configFile = config.sops.templates."octogram.conf".path;
  };
}
