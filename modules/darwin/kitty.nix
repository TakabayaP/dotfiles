{ ... }:
{
  # The application itself is installed by Homebrew cask.
  programs.kitty.package = null;

  programs.kitty.keybindings = {
    # Override Kitty's macOS default (hide_macos_app) and pass Cmd-H through
    # so Herdr can handle prefix+cmd+h while a prefix is active.
    "cmd+h" = "no_op";
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
