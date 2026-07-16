{ config, pkgs, ... }:
{
  imports = [
    ./alacritty.nix
    ./neovim.nix
    ./tmux.nix
  ];

  home.packages = [
    pkgs.fastfetch
    pkgs.nerd-fonts.hack
  ];

  programs.nh = {
    enable = true;
    flake = "${config.home.homeDirectory}/git/dotfiles";
  };
}
