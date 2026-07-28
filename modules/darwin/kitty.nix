{ ... }:
{
  # The application itself is installed by Homebrew cask.
  programs.kitty.package = null;

  programs.kitty.keybindings = {
    "cmd+p" = "send_text all \\e[1;2P";
    "shift+cmd+f" = "send_text all \\e[1;2Q";
    "cmd+l" = "send_text all \\e[1;2R";
    "cmd+[" = "send_text all \\e[1;2S";
    "cmd+]" = "send_text all \\e[15;2~";
    "cmd+s" = "send_text all \\e[17;2~";
    "cmd+j" = "send_text all \\e[18;2~";
    "cmd+/" = "send_text all \\e[19;2~";
  };
}
