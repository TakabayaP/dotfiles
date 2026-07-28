{ ... }:
{
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
