{ pkgs, ... }:
{
  programs.sketchybar = {
    enable = true;
    extraPackages = [ pkgs.jq ];
    config = {
      source = ./sketchybar;
      recursive = true;
    };
  };
}
