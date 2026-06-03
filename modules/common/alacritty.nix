{ pkgs, ... }:
{
  programs.alacritty = {
    enable = true;

    settings = {
      general.import = [
        "${pkgs.alacritty-theme}/share/alacritty-theme/alabaster_dark.toml"
      ];

      font = {
        size = 10.5;
        normal.family = "Hack Nerd Font Mono";
      };

      window.decorations = "None";
    };
  };
}
