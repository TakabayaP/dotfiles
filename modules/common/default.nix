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

  # tmux がクライアント端末として xterm-kitty を認識できるようにする。
  home.file.".terminfo/x/xterm-kitty".source =
    "${pkgs.kitty.terminfo}/share/terminfo/x/xterm-kitty";

  home.sessionVariables.EDITOR = "nvim";

  programs.nh = {
    enable = true;
    flake = "${config.home.homeDirectory}/git/dotfiles";
  };
}
