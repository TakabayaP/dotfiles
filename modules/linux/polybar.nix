{ lib, pkgs, ... }:
let
  polybarPackage = pkgs.polybarFull;

  fcitxStatus = pkgs.writeShellApplication {
    name = "polybar-ime";
    runtimeInputs = [ pkgs.qt6Packages.fcitx5-with-addons ];
    text = ''
      input_name="$(fcitx5-remote -n 2>/dev/null || true)"
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

      printf '%s %s\n' "$icon" "$label"
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

  polybarConfig = pkgs.writeText "polybar-config.ini" ''
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
    height = 38
    monitor = ''${env:MONITOR:}
    offset-x = 8
    offset-y = 6
    radius = 5
    fixed-center = true
    background = ''${colors.background}
    foreground = ''${colors.foreground}
    line-size = 0
    border-size = 0
    padding-left = 8
    padding-right = 8
    module-margin = 0
    font-0 = Hack Nerd Font:style=Regular:size=13;2
    font-1 = Hack Nerd Font:style=Bold:size=13;2
    modules-left = xworkspaces
    modules-center = date
    modules-right = battery ime pulseaudio cpu memory
    tray-position = right
    tray-padding = 8
    tray-maxsize = 16
    tray-background = ''${colors.module-background}
    wm-restack = i3
    enable-ipc = true
    cursor-click = pointer

    [module/xworkspaces]
    type = internal/i3
    pin-workspaces = true
    enable-click = true
    enable-scroll = true
    index-sort = true
    wrapping-scroll = false
    label-focused = %name%
    label-focused-background = ''${colors.accent}
    label-focused-foreground = ''${colors.background}
    label-focused-padding = 1
    label-unfocused = %name%
    label-unfocused-background = ''${colors.module-background}
    label-unfocused-foreground = ''${colors.inactive}
    label-unfocused-padding = 1
    label-visible = %name%
    label-visible-background = ''${colors.module-background}
    label-visible-foreground = ''${colors.foreground}
    label-visible-padding = 1
    label-urgent = %name%
    label-urgent-background = ''${colors.red}
    label-urgent-foreground = ''${colors.background}
    label-urgent-padding = 1

    [module/date]
    type = internal/date
    interval = 1
    date = %m/%d(%a)
    time = %H:%M
    format = <label>
    format-background = ''${colors.module-background}
    format-padding = 1
    label = 󰥔 %date% %time%

    [module/battery]
    type = custom/script
    exec = ${batteryStatus}/bin/polybar-battery
    interval = 30
    format = <label>
    format-background = ''${colors.module-background}
    format-padding = 1
    label = %output%

    [module/ime]
    type = custom/script
    exec = ${fcitxStatus}/bin/polybar-ime
    interval = 1
    format = <label>
    format-background = ''${colors.module-background}
    format-foreground = ''${colors.accent}
    format-padding = 1
    label = %output%

    [module/pulseaudio]
    type = internal/pulseaudio
    use-ui-max = true
    interval = 5
    format-volume = <ramp-volume><label-volume>
    format-volume-background = ''${colors.module-background}
    format-volume-padding = 1
    label-volume = %percentage%%
    ramp-volume-0 = 󰕿
    ramp-volume-1 = 󰖀
    ramp-volume-2 = 󰕾
    format-muted = <label-muted>
    format-muted-background = ''${colors.module-background}
    format-muted-foreground = ''${colors.red}
    format-muted-padding = 1
    label-muted = 󰝟 muted
    click-right = ${pkgs.pavucontrol}/bin/pavucontrol

    [module/cpu]
    type = internal/cpu
    interval = 3
    format = <label>
    format-background = ''${colors.module-background}
    format-foreground = ''${colors.accent}
    format-padding = 1
    label = CPU %percentage:2%%

    [module/memory]
    type = internal/memory
    interval = 3
    format = <label>
    format-background = ''${colors.module-background}
    format-foreground = ''${colors.green}
    format-padding = 1
    label = MEM %percentage_used:2%%
  '';

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
      pkill -TERM -f -- "${polybarPackage}/bin/polybar.*${polybarConfig}" 2>/dev/null || true
      sleep 0.2

      mapfile -t monitors < <(polybar --list-monitors 2>/dev/null | cut -d: -f1)
      if [ "''${#monitors[@]}" -eq 0 ]; then
        exec polybar --config=${polybarConfig} --reload sketchybar
      fi

      for monitor in "''${monitors[@]}"; do
        MONITOR="$monitor" polybar --config=${polybarConfig} --reload sketchybar &
      done
      wait
    '';
  };
in
{
  home.packages = [
    polybarPackage
    pkgs.pavucontrol
    startPolybar
  ];

  # Polybar is launched by i3 so it inherits the X11 DISPLAY and XAUTHORITY
  # variables that are not guaranteed to be present in a user systemd unit.
  xsession.windowManager.i3.extraConfig = lib.mkAfter ''
    exec_always --no-startup-id ${startPolybar}/bin/start-polybar
  '';
}
