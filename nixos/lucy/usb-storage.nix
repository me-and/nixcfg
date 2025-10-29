# TODO Finish attempting to work around the odd USB storage issues I'm seeing.
{
  boot.kernelParams = [ "usb-storage.quirks=174c:55aa:u" ];
}
