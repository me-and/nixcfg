{
  # List all keys here: if I'm using this machine as a build server, I'm okay
  # for any of my machines to use it.
  nix.localBuildServer.permittedSshKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJz5LaXgqbOYRmIcj6oMXYQ930S6owQyb4BkSKEb12ve root@saw"
  ];
}
