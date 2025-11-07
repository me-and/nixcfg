{ self }:
final: prev: {
  mylib = self.lib;
  mypkgs = self.legacyPackages."${final.stdenv.hostPlatform.system}";
}
