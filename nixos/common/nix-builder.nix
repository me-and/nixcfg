{
  # List all keys here: if I'm using this machine as a build server, I'm okay
  # for any of my machines to use it.
  nix.localBuildServer.permittedSshKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJz5LaXgqbOYRmIcj6oMXYQ930S6owQyb4BkSKEb12ve root@saw"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKpGUZf2mU5UVGORjA1fR9ezfEEtgGMmgUkcI7PXVbGv root@titmouse"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII7DD6pt5usNU2K6M0dRUK3EXJI0jFG3rYnoeIOCY/z1 root@ruddyduck"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIANXu4YVhR/mbmNWfGEZ7nN6g+4na2lBwhFr2AVabkVB root@redwing"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDDUclMliC1qWZ/zH8w5lTu+97dbZ0SYomRbCwmSN+7e root@cootlet"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAumnB96lZLVymTVbuoEWEx8BCNzx19pCKF+AjzJ/d9F root@rifleman"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICHScGt3WWGad9e581EBfkXKEbnqi3N0p2QO16cohSCl root@cootlet"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHMkEX7Mlt7lu+dTmXZD3bHVdEHJTt2rUFqVBWEvlthp root@twite"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDXgoou/euNtGtSn/yDKKUnSovuPJ0XfT6/VanCpozmm root@tern"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGWRtr9wrN7XBCAof2ePaxdTQYjftV9vDp+vLW2sZZ86 root@stilt"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIITc1n9QPj1OdRb2v7KXdhXGHT4y2PMcr1CEXVZVqEdU AdamDinwoodie@desktop-4d6hh84-nixos"
  ];
}
