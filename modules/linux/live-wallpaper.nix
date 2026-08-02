{ config, pkgs, ... }:
let
  defaultVideo = "${config.home.homeDirectory}/Videos/live-wallpaper.mp4";
  optimizedDownloadsVideo = "${config.home.homeDirectory}/Downloads/live_wallpaper_4k_60fps_quarter_speed.mp4";
  optimizedLowResDownloadsVideo = "${config.home.homeDirectory}/Downloads/live_wallpaper_1080p_60fps_quarter_speed.mp4";
  downloadsVideo = "${config.home.homeDirectory}/Downloads/live_wallpaper.mov";

  linuxLiveWallpaper = pkgs.writeShellApplication {
    name = "linux-live-wallpaper";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.gnused
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
          /usr/bin/mpv -wid WID "''${mpv_options[@]}" "$video"
      fi

      pids=()
      # Invoked indirectly by the EXIT trap below.
      # shellcheck disable=SC2329
      cleanup_children() {
        local exit_status="$?"
        trap - EXIT INT TERM

        for pid in "''${pids[@]}"; do
          kill "$pid" >/dev/null 2>&1 || true
        done
        for pid in "''${pids[@]}"; do
          wait "$pid" >/dev/null 2>&1 || true
        done

        exit "$exit_status"
      }
      trap cleanup_children EXIT
      trap 'exit 0' INT TERM

      for geometry in "''${monitor_geometries[@]}"; do
        monitor_video="$video"
        monitor_size="''${geometry%%+*}"
        monitor_width="''${monitor_size%x*}"
        monitor_height="''${monitor_size#*x}"
        if [ "$monitor_width" -lt 3000 ] && [ "$monitor_height" -lt 3000 ] \
          && [ -f "${optimizedLowResDownloadsVideo}" ]; then
          monitor_video="${optimizedLowResDownloadsVideo}"
        fi

        xwinwrap -g "$geometry" -st -sp -ni -b -nf -ov -- \
          /usr/bin/mpv -wid WID "''${mpv_options[@]}" "$monitor_video" &
        pids+=("$!")
      done

      if wait -n "''${pids[@]}"; then
        echo "linux-live-wallpaper: an xwinwrap child exited unexpectedly" >&2
        exit 1
      else
        child_status="$?"
        echo "linux-live-wallpaper: an xwinwrap child exited with status $child_status" >&2
        exit "$child_status"
      fi
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
