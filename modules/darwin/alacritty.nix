{ ... }:
let
  esc = builtins.fromJSON "\"\\u001b\"";
in
{
  programs.alacritty.package = null;

  programs.alacritty.settings.window.opacity = 0.8;

  programs.alacritty.settings.keyboard.bindings = [
    { key = "P"; mods = "Command"; chars = "${esc}[1;2P"; }
    { key = "F"; mods = "Command|Shift"; chars = "${esc}[1;2Q"; }
    { key = "L"; mods = "Command"; chars = "${esc}[1;2R"; }
    { key = "["; mods = "Command"; chars = "${esc}[1;2S"; }
    { key = "]"; mods = "Command"; chars = "${esc}[15;2~"; }
    { key = "S"; mods = "Command"; chars = "${esc}[17;2~"; }
    { key = "J"; mods = "Command"; chars = "${esc}[18;2~"; }
    { key = "/"; mods = "Command"; chars = "${esc}[19;2~"; }
  ];
}
