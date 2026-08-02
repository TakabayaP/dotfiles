{ config, pkgs, ... }:
let
  defaultVideo = "${config.home.homeDirectory}/Videos/live-wallpaper.mp4";
  optimizedDownloadsVideo = "${config.home.homeDirectory}/Downloads/live_wallpaper_4k_60fps_quarter_speed.mp4";
  downloadsVideo = "${config.home.homeDirectory}/Downloads/live_wallpaper.mov";

  linuxLiveWallpaper = pkgs.writeShellApplication {
    name = "linux-live-wallpaper";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.gnused
      pkgs.mpv
      pkgs.mpvpaper
      pkgs.xwinwrap
      pkgs.xrandr
    ];
    text = ''
      video="''${LIVE_WALLPAPER_VIDEO:-}"

      if [ -z "$video" ]; then
        if [ -f "${defaultVideo}" ]; then
          video="${defaultVideo}"
        elif [ -f "${optimizedDownloadsVideo}" ]; then
          video="${optimizedDownloadsVideo}"
        elif [ -f "${downloadsVideo}" ]; then
          video="${downloadsVideo}"
        fi
      fi

      if [ -z "$video" ] || [ ! -f "$video" ]; then
        echo "linux-live-wallpaper: video not found; add ${defaultVideo}, ${optimizedDownloadsVideo}, ${downloadsVideo}, or set LIVE_WALLPAPER_VIDEO" >&2
        exit 0
      fi

      mpv_options=(
        --no-audio
        --loop-file=inf
        --no-osc
        --no-input-default-bindings
        --really-quiet
        --hwdec=auto
        --keepaspect=yes
        --panscan=1.0
      )
      mpvpaper_options="''${mpv_options[*]}"

      if [ -n "''${WAYLAND_DISPLAY:-}" ]; then
        exec mpvpaper -o "$mpvpaper_options" '*' "$video"
      fi

      if [ -z "''${DISPLAY:-}" ]; then
        echo "linux-live-wallpaper: neither Wayland nor X11 is available" >&2
        exit 1
      fi

      # i3 uses X11 on this host. Start one override-redirect background per
      # monitor so landscape and portrait displays each get a fully covered
      # canvas. The below/sticky flags keep them behind normal windows.
      mapfile -t monitor_geometries < <(
        xrandr --query 2>/dev/null \
          | sed -nE 's/^[^ ]+ connected.* ([0-9]+x[0-9]+\+[0-9]+\+[0-9]+)( .*)$/\1/p'
      )

      if [ "''${#monitor_geometries[@]}" -eq 0 ]; then
        # Keep a useful fallback for X11 sessions without xrandr output.
        exec xwinwrap -fs -st -sp -ni -b -nf -ov -- \
          mpv -wid WID --vo=x11 "''${mpv_options[@]}" "$video"
      fi

      for geometry in "''${monitor_geometries[@]}"; do
        xwinwrap -g "$geometry" -st -sp -ni -b -nf -ov -- \
          mpv -wid WID --vo=x11 "''${mpv_options[@]}" "$video" &
      done
      wait
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
      RestartSec = 5;
    };

    Install.WantedBy = [ "graphical-session.target" ];
  };
}
