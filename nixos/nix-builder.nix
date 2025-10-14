let
  permittedSshKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIITc1n9QPj1OdRb2v7KXdhXGHT4y2PMcr1CEXVZVqEdU AdamDinwoodie@desktop-4d6hh84-nixos"
  ];
in
{
  users.users.nixremote = {
    isNormalUser = true;
    description = "Remote nix build account";
    openssh.authorizedKeys.keys = map (
      key: "command=\"/run/current-system/sw/bin/nix-store --serve --write\" ${key}"
    ) permittedSshKeys;
    group = "nixremote";
  };
  users.groups.nixremote = { };

  nix.settings.trusted-users = [ "nixremote" ];
  nix.sshServe = {
    enable = true;
    write = true;
    trusted = true;
    keys = permittedSshKeys;
  };
}
