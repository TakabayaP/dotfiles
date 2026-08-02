{ config, pkgs, ... }:
let
  defaultVideo = "${config.home.homeDirectory}/Videos/live-wallpaper.mp4";
  optimizedDownloadsVideo = "${config.home.homeDirectory}/Downloads/live_wallpaper_4k_60fps_quarter_speed.mp4";
  optimizedLowResDownloadsVideo = "${config.home.homeDirectory}/Downloads/live_wallpaper_1080p_60fps_quarter_speed.mp4";
  downloadsVideo = "${config.home.homeDirectory}/Downloads/live_wallpaper.mov";

  linuxLiveWallpaper = pkgs.writeShellApplication {
    name = "linux-live-wallpaper";
    runtimeInputs = [ pkgs.xwinwrap ];
    text = ''
      video="''${LIVE_WALLPAPER_VIDEO:-}"

      if [ -z "$video" ]; then
        if [ -f "${defaultVideo}" ]; then
          video="${defaultVideo}"
        elif [ -f "${optimizedDownloadsVideo}" ]; then
          video="${optimizedDownloadsVideo}"
        elif [ -f "${optimizedLowResDownloadsVideo}" ]; then
          video="${optimizedLowResDownloadsVideo}"
        elif [ -f "${downloadsVideo}" ]; then
          video="${downloadsVideo}"
        fi
      fi

      if [ -z "$video" ] || [ ! -f "$video" ]; then
        echo "linux-live-wallpaper: video not found; add ${defaultVideo}, ${optimizedDownloadsVideo}, ${optimizedLowResDownloadsVideo}, ${downloadsVideo}, or set LIVE_WALLPAPER_VIDEO" >&2
        exit 0
      fi

      if [ -z "''${DISPLAY:-}" ]; then
        echo "linux-live-wallpaper: X11 DISPLAY is not available" >&2
        exit 1
      fi

      if [ ! -x /usr/bin/mpv ]; then
        echo "linux-live-wallpaper: required host player /usr/bin/mpv was not found" >&2
        exit 78
      fi

      mpv_options=(
        --no-audio
        --loop-file=inf
        --no-osc
        --no-input-default-bindings
        --really-quiet
        --keepaspect=yes
        --panscan=1.0
        --vo=gpu
        --gpu-context=x11egl
        --gpu-api=opengl
        --hwdec=nvdec
      )

      # X11 exposes the complete multi-monitor layout as one root canvas.
      # Rendering once across that canvas makes each monitor show its own
      # section of one continuous video while decoding the stream only once.
      exec xwinwrap -fs -st -sp -ni -b -nf -ov -- \
        /usr/bin/mpv -wid WID "''${mpv_options[@]}" "$video"
    '';
  };
in
{
  home.packages = [ linuxLiveWallpaper ];

  systemd.user.services.live-wallpaper = {
    Unit = {
      Description = "Play a video as the Linux desktop wallpaper";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "${linuxLiveWallpaper}/bin/linux-live-wallpaper";
      Restart = "on-failure";
      RestartPreventExitStatus = 78;
      RestartSec = 5;
    };

    Install.WantedBy = [ "graphical-session.target" ];
  };
}
