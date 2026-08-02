{ config, pkgs, ... }:
{
  imports = [
    ./alacritty.nix
    ./herdr.nix
    ./kitty.nix
    ./neovim.nix
    ./nvim-mcp.nix
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

  programs.btop = {
    enable = true;
    settings = {
      # Preserve the existing preference: update the top process immediately
      # instead of smoothing CPU sort changes over time.
      proc_sorting = "cpu direct";
      theme_background = false;
    };
  };

  home.sessionVariables = {
    EDITOR = "nvim";
    TERMINAL = "kitty";
  };

  programs.nh = {
    enable = true;
    flake = "${config.home.homeDirectory}/git/dotfiles";
  };
}
