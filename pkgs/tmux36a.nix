{
  tmux,
  fetchFromGitHub,
  fetchpatch,
}:
tmux.overrideAttrs (
  finalAttrs: prevAttrs: {
    version = "3.6a";
    src = fetchFromGitHub {
      inherit (prevAttrs.src) owner repo;
      tag = finalAttrs.version;
      hash = "sha256-VwOyR9YYhA/uyVRJbspNrKkJWJGYFFktwPnnwnIJ97s=";
    };
    patches = prevAttrs.patches or [ ] ++ [
      (fetchpatch {
        name = "tmux-control-notify-uninitialized.patch";
        url = "https://github.com/tmux/tmux/commit/e5a2a25fafb8ee107c230d8acad694f6b635f8bb.patch";
        hash = "sha256-UPbhMNnH1WJwTH/LVwjVonTqvNhyuniUrYm7iLVkCfg=";
      })
    ];
  }
)
