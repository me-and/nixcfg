{
  programs.plasma = {
    input.keyboard = {
      layouts = [
        {
          layout = "gb";
          variant = "dvorak";
        }
        { layout = "gb"; }
      ];
      model = "pc105";
      numlockOnStartup = "on";
    };
    shortcuts = {
      "KDE Keyboard Layout Switcher"."Switch to Last-Used Keyboard Layout" = [ ];
      "KDE Keyboard Layout Switcher"."Switch to Next Keyboard Layout" = "Meta+Space";
    };

    input.touchpads = [
      # Framework 16 touchpad
      {
        name = "PIXA3854:00 093A:0274 Touchpad";
        vendorId = "093a";
        productId = "0274";
        naturalScroll = true;
      }
    ];
  };
}
