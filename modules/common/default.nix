{ pkgs, ... }:
{
  imports = [
    ./neovim.nix
    ./alacritty.nix
  ];

  home.packages = [
    pkgs.fastfetch
  ];
}

