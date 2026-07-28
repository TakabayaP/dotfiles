{ ... }:
{
  programs.kitty = {
    enable = true;

    font = {
      name = "Hack Nerd Font Mono";
      size = 10.5;
    };

    settings = {
      background_opacity = 0.8;
      hide_window_decorations = true;
      copy_on_select = "clipboard";
      confirm_os_window_close = 0;

      # Alabaster Dark
      background = "#0E1415";
      foreground = "#CECECE";
      cursor = "#CECECE";
      cursor_text_color = "#0E1415";

      color0 = "#0E1415";
      color1 = "#e25d56";
      color2 = "#73ca50";
      color3 = "#e9bf57";
      color4 = "#4a88e4";
      color5 = "#915caf";
      color6 = "#23acdd";
      color7 = "#f0f0f0";

      color8 = "#777777";
      color9 = "#f36868";
      color10 = "#88db3f";
      color11 = "#f0bf7a";
      color12 = "#6f8fdb";
      color13 = "#e987e9";
      color14 = "#4ac9e2";
      color15 = "#FFFFFF";
    };
  };
}
