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
        echo "linux-live-wallpaper: video not found; add ${defaultVideo}, ${optimizedDownloadsVideo}, ${optimizedLowResDownloadsVideo}, ${downloadsVideo}, or set LIVE_WALLPAPER_VIDEO" >&2
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

      # Nix's mpv does not automatically see Arch's host NVIDIA GLVND
      # libraries. Without these paths, --hwdec=auto falls back to software
      # decoding. Use the GPU-backed X11 output and NVDEC when the host has
      # the NVIDIA runtime installed, while retaining a generic X11 fallback.
      x11_mpv_options=(--vo=x11)
      if [ -f /usr/share/glvnd/egl_vendor.d/10_nvidia.json ] \
        && [ -f /usr/lib/libEGL_nvidia.so.0 ] \
        && [ -f /usr/lib/libcuda.so.1 ] \
        && [ -f /usr/lib/libnvcuvid.so.1 ]; then
        export LD_LIBRARY_PATH="/usr/lib:/usr/lib/nvidia''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
        export __EGL_VENDOR_LIBRARY_FILENAMES=/usr/share/glvnd/egl_vendor.d/10_nvidia.json
        export __GLX_VENDOR_LIBRARY_NAME=nvidia
        if [ -f /usr/share/vulkan/icd.d/nvidia_icd.json ]; then
          export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json
        fi
        x11_mpv_options=(
          --vo=gpu
          --gpu-context=x11egl
          --gpu-api=opengl
          --hwdec=nvdec
        )
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
          mpv -wid WID "''${mpv_options[@]}" "''${x11_mpv_options[@]}" "$video"
      fi

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
          mpv -wid WID "''${mpv_options[@]}" "''${x11_mpv_options[@]}" "$monitor_video" &
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
