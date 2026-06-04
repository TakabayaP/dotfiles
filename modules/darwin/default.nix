{ ... }:
{
  imports = [
    ./aerospace.nix
    ./alacritty.nix
    ./live-wallpaper.nix
    ./sketchybar.nix
  ];

  services.jankyborders = {
    enable = true;
    settings = {
      style = "square";
      width = 5.0;
      hidpi = "on";
      active_color = "0x82959EFF";
    };
  };
}
