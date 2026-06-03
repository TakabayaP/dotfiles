{ username, ... }:
{
  _module.args.hostConfig = {
    xrandrCommand = "xrandr --output HDMI-0 --off --output DP-0 --mode 1920x1080 --pos 0x540 --rotate normal --output DP-1 --off --output DP-2 --mode 1920x1080 --pos 1920x120 --rotate right --output DP-3 --off --output DP-4 --mode 3840x2160 --pos 3000x0 --rotate normal --output DP-5 --off";
    backgroundImage = "/usr/share/backgrounds/archlinux/sunset.jpg";
    i3WorkspaceOutputs = ''
      workspace 1 output DP-0
      workspace 2 output DP-2
      workspace 3 output DP-4
      workspace 4 output DP-0
      workspace 5 output DP-2
      workspace 6 output DP-4
    '';
  };

  home.username = username;
  home.homeDirectory = "/home/${username}";

  imports = [
    ../../modules/common/default.nix
    ../../modules/linux/default.nix
  ];
}
