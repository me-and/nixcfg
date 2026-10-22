# https://github.com/NixOS/nixpkgs/pull/576063
final: prev: {
  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
    (pyfinal: pyprev: {
      pyopenjtalk-plus = pyprev.pyopenjtalk-plus.overridePythonAttrs (prevAttrs: {
        patches = prevAttrs.patches or [ ] ++ [
          (final.fetchpatch {
            name = "fix-cython-3.3.0.patch";
            url = "https://github.com/tsukumijima/pyopenjtalk-plus/commit/90b644f9e9d397882e6eafe4dcd1843a4fde6a63.patch";
            includes = [ "tests/test_frontend.py" ];
            hash = "sha256-Jb7T/bRUHxqwBLwV6xYC/teaFHm5GmqJxA7sCX+oiNI=";
          })
        ];
      });
    })
  ];
}
