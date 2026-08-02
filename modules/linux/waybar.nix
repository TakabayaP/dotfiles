{ pkgs, ... }:
let
  fcitxStatus = pkgs.writeShellApplication {
    name = "waybar-ime";
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

      printf '{"text":"%s %s","tooltip":"%s"}\n' "$icon" "$label" "$input_name"
    '';
  };

  waybarConfig = pkgs.writeText "waybar-config.json" (builtins.toJSON {
    layer = "top";
    position = "top";
    height = 38;
    margin-top = 6;
    margin-left = 8;
    margin-right = 8;
    spacing = 8;
    modules-left = [ "i3/workspaces" ];
    modules-center = [ "clock" ];
    modules-right = [
      "battery"
      "custom/ime"
      "pulseaudio"
      "cpu"
      "memory"
      "tray"
    ];

    "i3/workspaces" = {
      format = "{name}";
      on-click = "activate";
      sort-by-number = true;
      persistent-workspaces = {
        "1" = [ ];
        "2" = [ ];
        "3" = [ ];
        "4" = [ ];
        "5" = [ ];
        "6" = [ ];
        "7" = [ ];
        "8" = [ ];
        "9" = [ ];
        "10" = [ ];
      };
    };

    clock = {
      format = "󰥔 {:%m/%d(%a) %H:%M}";
      interval = 1;
      tooltip-format = "{:%Y-%m-%d %H:%M:%S}";
    };

    battery = {
      format = "{icon} {capacity}%";
      format-charging = "󰂄 {capacity}%";
      format-full = "󰁹 {capacity}%";
      format-icons = [ "󰂎" "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" ];
      interval = 30;
      states = {
        warning = 30;
        critical = 15;
      };
    };

    "custom/ime" = {
      exec = "${fcitxStatus}/bin/waybar-ime";
      return-type = "json";
      interval = 1;
      format = "{}";
    };

    pulseaudio = {
      format = "{icon} {volume}%";
      format-bluetooth = "{icon} {volume}%";
      format-muted = "󰝟 muted";
      format-icons = {
        default = [ "󰕿" "󰖀" "󰕾" ];
        bluetooth = "󰂰";
      };
      on-click = "pavucontrol";
      tooltip-format = "{desc}";
    };

    cpu = {
      format = "CPU {usage}%";
      interval = 3;
      states = {
        warning = 70;
        critical = 90;
      };
    };

    memory = {
      format = "MEM {percentage}%";
      interval = 3;
      states = {
        warning = 70;
        critical = 90;
      };
    };

    tray = {
      icon-size = 16;
      spacing = 8;
    };
  });

  waybarStyle = pkgs.writeText "waybar-style.css" ''
    * {
      border: none;
      border-radius: 0;
      font-family: "Hack Nerd Font";
      font-size: 13px;
      min-height: 0;
    }

    window#waybar {
      background: rgba(30, 30, 46, 0.80);
      color: #cdd6f4;
    }

    #workspaces,
    #clock,
    #battery,
    #custom-ime,
    #pulseaudio,
    #cpu,
    #memory,
    #tray {
      background: rgba(49, 50, 68, 0.80);
      border-radius: 5px;
      margin: 6px 4px;
      padding: 0 10px;
    }

    #workspaces {
      padding: 0 4px;
    }

    #workspaces button {
      background: transparent;
      color: #6c7086;
      padding: 0 8px;
    }

    #workspaces button.active {
      background: #89b4fa;
      color: #1e1e2e;
    }

    #workspaces button.urgent,
    #battery.warning {
      color: #f9e2af;
    }

    #battery.critical {
      color: #f38ba8;
    }

    #clock,
    #custom-ime {
      color: #89b4fa;
    }

    #cpu {
      color: #89b4fa;
    }

    #memory {
      color: #a6e3a1;
    }

    #tray {
      padding-left: 8px;
      padding-right: 8px;
    }
  '';
in
{
  home.packages = [ pkgs.waybar ];

  systemd.user.services.waybar = {
    Unit = {
      Description = "SketchyBar-like status bar for i3";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "${pkgs.waybar}/bin/waybar -c ${waybarConfig} -s ${waybarStyle}";
      Restart = "on-failure";
      RestartSec = 2;
    };

    Install.WantedBy = [ "graphical-session.target" ];
  };
}
