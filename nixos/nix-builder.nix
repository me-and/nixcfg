{
  nix.sshServe = {
    enable = true;
    write = true;
    trusted = true;
    protocol = "ssh-ng";
  };
}
