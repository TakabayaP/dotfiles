{ ... }:
let
  esc = builtins.fromJSON "\"\\u001b\"";
in
{
  programs.alacritty.settings.keyboard.bindings = [
    { key = "P"; mods = "Control"; chars = "${esc}[1;2P"; }
    { key = "F"; mods = "Control|Shift"; chars = "${esc}[1;2Q"; }
    { key = "L"; mods = "Control"; chars = "${esc}[1;2R"; }
    { key = "["; mods = "Control"; chars = "${esc}[1;2S"; }
    { key = "]"; mods = "Control"; chars = "${esc}[15;2~"; }
    { key = "S"; mods = "Control"; chars = "${esc}[17;2~"; }
    { key = "J"; mods = "Control"; chars = "${esc}[18;2~"; }
    { key = "/"; mods = "Control"; chars = "${esc}[19;2~"; }
  ];
}
