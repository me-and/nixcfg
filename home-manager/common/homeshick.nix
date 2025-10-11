{
  home.activation.homeshick = ''
    if [[ -e "$HOME"/.homesick ]]; then
        warnEcho '~/.homesick exists, and should probably be removed.'
    fi
  '';
}
