{ config, pkgs, ... }:
{
  imports = [
    ./alacritty.nix
    ./herdr.nix
    ./neovim.nix
    ./tmux.nix
  ];

  home.packages = [
    pkgs.fastfetch
    pkgs.go
    pkgs.nerd-fonts.hack
  ];

  programs.nh = {
    enable = true;
    flake = "${config.home.homeDirectory}/git/dotfiles";
  };
}
