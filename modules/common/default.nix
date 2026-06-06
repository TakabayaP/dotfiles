{ pkgs, ... }:
{
  imports = [
    ./alacritty.nix
    ./neovim.nix
  ];

  home.packages = [
    pkgs.fastfetch
  ];
}
