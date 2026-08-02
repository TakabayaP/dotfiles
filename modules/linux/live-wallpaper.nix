{ config, pkgs, ... }:
let
  defaultVideo = "${config.home.homeDirectory}/Videos/live-wallpaper.mp4";

  linuxLiveWallpaper = pkgs.writeShellApplication {
    name = "linux-live-wallpaper";
    runtimeInputs = [
      pkgs.mpv
      pkgs.mpvpaper
      pkgs.xwinwrap
    ];
    text = ''
      video="''${LIVE_WALLPAPER_VIDEO:-${defaultVideo}}"

      if [ ! -f "$video" ]; then
        echo "linux-live-wallpaper: video not found; set LIVE_WALLPAPER_VIDEO or add $video" >&2
        exit 0
      fi

      mpv_options="--no-audio --loop-file=inf --no-osc --no-input-default-bindings --really-quiet --hwdec=auto"

      if [ -n "''${WAYLAND_DISPLAY:-}" ]; then
        exec mpvpaper -o "$mpv_options" '*' "$video"
      fi

      if [ -z "''${DISPLAY:-}" ]; then
        echo "linux-live-wallpaper: neither Wayland nor X11 is available" >&2
        exit 1
      fi

      # i3 uses X11 on this host. xwinwrap keeps mpv below normal windows,
      # sticky across workspaces, and outside task switching.
      # WID is supplied by xwinwrap to mpv for the embedded desktop window.
      exec xwinwrap -fs -fdt -ni -b -nf -- \
        mpv --wid=WID $mpv_options "$video"
    '';
  };
in
{
  home.packages = [ linuxLiveWallpaper ];
  home.sessionVariables.LIVE_WALLPAPER_VIDEO = defaultVideo;

  systemd.user.services.live-wallpaper = {
    Unit = {
      Description = "Play a video as the Linux desktop wallpaper";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "${linuxLiveWallpaper}/bin/linux-live-wallpaper";
      Restart = "on-failure";
      RestartSec = 5;
    };

    Install.WantedBy = [ "graphical-session.target" ];
  };
}
