# https://github.com/NixOS/nixpkgs/pull/576062
final: prev:
let
  inherit (final) lib;
in
{
  speechd = prev.speechd.overrideAttrs (
    prevAttrs:
    let
      buildPartition = builtins.partition (p: p.pname == "python3") prevAttrs.buildInputs;
      expectedPartitioning = builtins.length buildPartition.right == 1;
    in
    {
      buildInputs = buildPartition.wrong;
      nativeBuildInputs =
        prevAttrs.nativeBuildInputs
        ++ lib.warnIf (!expectedPartitioning) "possibly unnecessary speechd overlay" buildPartition.right;
    }
  );
}
