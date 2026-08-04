# https://github.com/NixOS/nixpkgs/pull/548843
final: prev: {
  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
    (finalPs: prevPs: {
      typed-argparse = prevPs.typed-argparse.overridePythonAttrs (prevAttrs: {
        disabledTests = prevAttrs.disabledTests ++ [
          "test_dynamic_choices"
          "test_literal__basics"
          "test_enum__basics[False]"
          "test_enum__basics[True]"
          "test_subparsers_common_args__subparser_after_positional"
        ];
      });
    })
  ];
}
