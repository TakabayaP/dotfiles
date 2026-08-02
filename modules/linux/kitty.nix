{ pkgs, ... }:
let
  hostKitty = pkgs.writeShellScriptBin "kitty" ''
    export GLFW_IM_MODULE=ibus
    exec /usr/bin/kitty "$@"
  '';
in
{
  # On Arch, use the pacman kitty so its GLFW/GLVND stack stays aligned with
  # the host X11 and NVIDIA driver. The wrapper enables kitty's IBus frontend,
  # which connects to Fcitx5 without replacing the host kitty binary.
  programs.kitty.package = null;

  home.packages = [ hostKitty ];
  home.sessionVariables.GLFW_IM_MODULE = "ibus";

  programs.kitty.keybindings = {
    "ctrl+p" = "send_text all \\e[1;2P";
    "shift+ctrl+f" = "send_text all \\e[1;2Q";
    "ctrl+l" = "send_text all \\e[1;2R";
    "ctrl+[" = "send_text all \\e[1;2S";
    "ctrl+]" = "send_text all \\e[15;2~";
    "ctrl+s" = "send_text all \\e[17;2~";
    "ctrl+j" = "send_text all \\e[18;2~";
    "ctrl+/" = "send_text all \\e[19;2~";
  };
}
