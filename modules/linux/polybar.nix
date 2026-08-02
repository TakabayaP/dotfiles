{ lib, pkgs, ... }:
let
  polybarPackage = pkgs.polybarFull;

  workspaceStatus = pkgs.writeShellApplication {
    name = "polybar-workspaces";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.i3
      pkgs.jq
    ];
    text = ''
      i3_command="${pkgs.i3}/bin/i3-msg"

      while true; do
        focused="$($i3_command -t get_workspaces 2>/dev/null | jq -r '.[] | select(.focused) | .num' | head -n 1 || true)"
        [ -n "$focused" ] || focused=1

        output=""
        for workspace in $(seq 1 10); do
          if [ "$workspace" = "$focused" ]; then
            background="#89b4fa"
            foreground="#1e1e2e"
          else
            background="#313244"
            foreground="#6c7086"
          fi

          output="''${output}%{A1:''${i3_command} workspace number ''${workspace}:}%{B''${background}}%{F''${foreground}} ''${workspace} %{F-}%{B-}%{A}"
        done

        printf '%s\n' "$output"
        sleep 1
      done
    '';
  };

  fcitxStatus = pkgs.writeShellApplication {
    name = "polybar-ime";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.qt6Packages.fcitx5-with-addons
    ];
    text = ''
      while true; do
        input_name="$(fcitx5-remote -n 2>/dev/null || true)"
        input_name="$(printf '%s' "$input_name" | tr '[:upper:]' '[:lower:]')"

        case "$input_name" in
          *skk*|*hiragana*)
            icon="あ"
            label="JA"
            ;;
          *katakana*)
            icon="ア"
            label="JA"
            ;;
          *hangul*|*korean*)
            icon="한"
            label="KO"
            ;;
          *chinese*|*pinyin*)
            icon="中"
            label="ZH"
            ;;
          *)
            icon="A"
            label="EN"
            ;;
        esac

        printf 'IME %s %s\n' "$icon" "$label"
        sleep 1
      done
    '';
  };

  cpuStatus = pkgs.writeShellApplication {
    name = "polybar-cpu";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.gawk
    ];
    text = ''
      spark_chars=(▁ ▂ ▃ ▄ ▅ ▆ ▇ █)
      history="▁▁▁▁▁▁▁▁▁▁▁▁"

      cpu_stats() {
        awk '/^cpu / { idle=$5+$6; total=0; for (i=2; i<=NF; i++) total += $i; print idle, total; exit }' /proc/stat
      }

      previous_idle=0
      previous_total=0
      read -r previous_idle previous_total < <(cpu_stats)
      printf 'CPU %s 0%%\n' "$history"

      while true; do
        sleep 3
        idle=""
        total=""
        read -r idle total < <(cpu_stats)
        if [ -z "$idle" ] || [ -z "$total" ]; then
          continue
        fi

        total_delta=$((total - previous_total))
        idle_delta=$((idle - previous_idle))
        usage=0
        if [ "$total_delta" -gt 0 ]; then
          usage=$((100 * (total_delta - idle_delta) / total_delta))
        fi
        [ "$usage" -lt 0 ] && usage=0
        [ "$usage" -gt 100 ] && usage=100

        level=$((usage * 7 / 100))
        history="''${history}''${spark_chars[level]}"
        if [ "''${#history}" -gt 12 ]; then
          history="''${history: -12}"
        fi

        printf 'CPU %s %3d%%\n' "$history" "$usage"
        previous_idle="$idle"
        previous_total="$total"
      done
    '';
  };

  memoryStatus = pkgs.writeShellApplication {
    name = "polybar-memory";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.gawk
    ];
    text = ''
      spark_chars=(▁ ▂ ▃ ▄ ▅ ▆ ▇ █)
      history="▁▁▁▁▁▁▁▁▁▁▁▁"

      memory_stats() {
        awk '/MemTotal:/ { total=$2 } /MemAvailable:/ { available=$2 } END { if (total > 0) print total-available, total }' /proc/meminfo
      }

      printf 'MEM %s 0%%\n' "$history"

      while true; do
        sleep 3
        used=""
        total=""
        read -r used total < <(memory_stats)
        if [ -z "$used" ] || [ -z "$total" ] || [ "$total" -le 0 ]; then
          continue
        fi

        usage=$((100 * used / total))
        [ "$usage" -lt 0 ] && usage=0
        [ "$usage" -gt 100 ] && usage=100

        level=$((usage * 7 / 100))
        history="''${history}''${spark_chars[level]}"
        if [ "''${#history}" -gt 12 ]; then
          history="''${history: -12}"
        fi

        printf 'MEM %s %3d%%\n' "$history" "$usage"
      done
    '';
  };

  vramStatus = pkgs.writeShellApplication {
    name = "polybar-vram";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      nvidia_smi="$(command -v nvidia-smi || true)"
      if [ -z "$nvidia_smi" ] && [ -x /usr/bin/nvidia-smi ]; then
        nvidia_smi=/usr/bin/nvidia-smi
      fi

      if [ -z "$nvidia_smi" ]; then
        printf 'GPU N/A VRAM N/A\n'
        exit 0
      fi

      while true; do
        stats="$($nvidia_smi --query-gpu=utilization.gpu,memory.used,memory.total --format=csv,noheader,nounits 2>/dev/null | head -n 1 | tr -d ' ' || true)"
        if [[ "$stats" =~ ^[0-9]+,[0-9]+,[0-9]+$ ]]; then
          IFS=',' read -r gpu used total <<< "$stats"
          memory_usage=$((100 * used / total))
          printf 'GPU %s%% VRAM %s%%\n' "$gpu" "$memory_usage"
        else
          printf 'GPU N/A VRAM N/A\n'
        fi
        sleep 3
      done
    '';
  };

  batteryStatus = pkgs.writeShellApplication {
    name = "polybar-battery";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      battery_dir=""
      for candidate in /sys/class/power_supply/BAT*; do
        if [ -d "$candidate" ]; then
          battery_dir="$candidate"
          break
        fi
      done

      [ -n "$battery_dir" ] || exit 0

      capacity="$(cat "$battery_dir/capacity" 2>/dev/null || echo 0)"
      status="$(cat "$battery_dir/status" 2>/dev/null || true)"

      if [ "$status" = "Charging" ]; then
        icon="󰂄"
      elif [ "$capacity" -ge 80 ]; then
        icon="󰂁"
      elif [ "$capacity" -ge 60 ]; then
        icon="󰁿"
      elif [ "$capacity" -ge 40 ]; then
        icon="󰁽"
      elif [ "$capacity" -ge 20 ]; then
        icon="󰁻"
      else
        icon="󰂎"
      fi

      printf '%s %s%%\n' "$icon" "$capacity"
    '';
  };

  wallpaperControl = pkgs.writeShellApplication {
    name = "toggle-live-wallpaper";
    runtimeInputs = [ pkgs.systemd ];
    text = ''
      action="''${1:-toggle}"

      case "$action" in
        on|start)
          exec systemctl --user start live-wallpaper.service
          ;;
        off|stop)
          exec systemctl --user stop live-wallpaper.service
          ;;
        toggle)
          if systemctl --user is-active --quiet live-wallpaper.service; then
            exec systemctl --user stop live-wallpaper.service
          else
            exec systemctl --user start live-wallpaper.service
          fi
          ;;
        status)
          if systemctl --user is-active --quiet live-wallpaper.service; then
            printf 'on\n'
          else
            printf 'off\n'
          fi
          ;;
        *)
          echo "usage: toggle-live-wallpaper [on|off|toggle|status]" >&2
          exit 2
          ;;
      esac
    '';
  };

  liveWallpaperStatus = pkgs.writeShellApplication {
    name = "polybar-live-wallpaper";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      while true; do
        if [ "$(${wallpaperControl}/bin/toggle-live-wallpaper status)" = "on" ]; then
          printf 'LIVE\n'
        else
          printf 'OFF\n'
        fi
        sleep 2
      done
    '';
  };

  togglePolybar = pkgs.writeShellApplication {
    name = "toggle-polybar";
    runtimeInputs = [ polybarPackage ];
    text = ''
      exec polybar-msg cmd toggle
    '';
  };

  polybarConfig = tray:
    pkgs.writeText
      (if tray then "polybar-config-with-tray.ini" else "polybar-config.ini")
      ''
    [colors]
    background = #cc1e1e2e
    module-background = #cc313244
    foreground = #cdd6f4
    inactive = #6c7086
    accent = #89b4fa
    green = #a6e3a1
    yellow = #f9e2af
    red = #f38ba8

    [bar/sketchybar]
    width = 100%
    height = 28
    monitor = ''${env:MONITOR:}
    offset-x = 4
    offset-y = 4
    radius = 4
    fixed-center = true
    background = ''${colors.background}
    foreground = ''${colors.foreground}
    line-size = 0
    border-size = 0
    padding-left = 4
    padding-right = 4
    module-margin = 1
    font-0 = Hack Nerd Font:style=Regular:size=11;2
    font-1 = Hack Nerd Font:style=Bold:size=11;2
    modules-left = workspaces
    modules-center = date
    modules-right = battery ime live-wallpaper pulseaudio cpu memory vram${if tray then " tray" else ""}
    wm-restack = i3
    enable-ipc = true
    cursor-click = pointer

    [module/workspaces]
    type = custom/script
    exec = ${workspaceStatus}/bin/polybar-workspaces
    tail = true
    format = <label>
    format-padding = 0
    label = %output%

    [module/date]
    type = internal/date
    interval = 1
    date = %m/%d(%a)
    time = %H:%M
    format = <label>
    format-background = ''${colors.module-background}
    format-padding = 0
    label = 󰥔 %date% %time%

    [module/battery]
    type = custom/script
    exec = ${batteryStatus}/bin/polybar-battery
    interval = 30
    format = <label>
    format-background = ''${colors.module-background}
    format-padding = 0
    label = %output%

    [module/ime]
    type = custom/script
    exec = ${fcitxStatus}/bin/polybar-ime
    tail = true
    format = <label>
    format-background = ''${colors.module-background}
    format-foreground = ''${colors.accent}
    format-padding = 0
    label = %output%

    [module/pulseaudio]
    type = internal/pulseaudio
    use-ui-max = true
    interval = 5
    format-volume = <ramp-volume><label-volume>
    format-volume-background = ''${colors.module-background}
    format-volume-padding = 0
    label-volume = %percentage%%
    ramp-volume-0 = 󰕿
    ramp-volume-1 = 󰖀
    ramp-volume-2 = 󰕾
    format-muted = <label-muted>
    format-muted-background = ''${colors.module-background}
    format-muted-foreground = ''${colors.red}
    format-muted-padding = 0
    label-muted = 󰝟 muted
    click-right = ${pkgs.pavucontrol}/bin/pavucontrol

    [module/live-wallpaper]
    type = custom/script
    exec = ${liveWallpaperStatus}/bin/polybar-live-wallpaper
    tail = true
    format = <label>
    format-background = ''${colors.module-background}
    format-foreground = ''${colors.yellow}
    format-padding = 0
    label = 󰸉 %output%
    click-left = ${wallpaperControl}/bin/toggle-live-wallpaper toggle
    click-right = ${wallpaperControl}/bin/toggle-live-wallpaper off

    [module/tray]
    type = internal/tray
    format = <tray>
    format-background = ''${colors.module-background}
    format-padding = 0
    tray-spacing = 4px
    tray-size = 100%

    [module/cpu]
    type = custom/script
    exec = ${cpuStatus}/bin/polybar-cpu
    tail = true
    format = <label>
    format-background = ''${colors.module-background}
    format-foreground = ''${colors.accent}
    format-padding = 0
    label = %output%

    [module/memory]
    type = custom/script
    exec = ${memoryStatus}/bin/polybar-memory
    tail = true
    format = <label>
    format-background = ''${colors.module-background}
    format-foreground = ''${colors.green}
    format-padding = 0
    label = %output%

    [module/vram]
    type = custom/script
    exec = ${vramStatus}/bin/polybar-vram
    tail = true
    format = <label>
    format-background = ''${colors.module-background}
    format-foreground = ''${colors.yellow}
    format-padding = 0
    label = %output%
  '';

  polybarConfigWithTray = polybarConfig true;
  polybarConfigWithoutTray = polybarConfig false;

  startPolybar = pkgs.writeShellApplication {
    name = "start-polybar";
    runtimeInputs = [
      polybarPackage
      pkgs.coreutils
      pkgs.procps
    ];
    text = ''
      # Nix wraps Polybar, so its process name is not literally "polybar".
      # Match this managed config path to avoid accumulating bars on reload.
      pkill -TERM -f -- 'polybar --config=/nix/store/[^ ]*polybar-config[^ ]*[.]ini' 2>/dev/null || true
      sleep 0.2

      mapfile -t monitors < <(polybar --list-monitors 2>/dev/null | cut -d: -f1)
      if [ "''${#monitors[@]}" -eq 0 ]; then
        exec polybar --config=${polybarConfigWithTray} --reload sketchybar
      fi

      first_monitor=true
      for monitor in "''${monitors[@]}"; do
        if [ "$first_monitor" = true ]; then
          config=${polybarConfigWithTray}
          first_monitor=false
        else
          config=${polybarConfigWithoutTray}
        fi
        MONITOR="$monitor" polybar --config="$config" --reload sketchybar &
      done
      wait
    '';
  };
in
{
  home.packages = [
    polybarPackage
    pkgs.pavucontrol
    wallpaperControl
    togglePolybar
    startPolybar
  ];

  # Polybar is launched by i3 so it inherits the X11 DISPLAY and XAUTHORITY
  # variables that are not guaranteed to be present in a user systemd unit.
  xsession.windowManager.i3.extraConfig = lib.mkAfter ''
    exec_always --no-startup-id ${startPolybar}/bin/start-polybar
  '';
}
