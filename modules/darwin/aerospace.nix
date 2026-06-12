{ pkgs, ... }:
let
  tomlFormat = pkgs.formats.toml { };
  aerospaceConfig = {
    start-at-login = true;

    automatically-unhide-macos-hidden-apps = false;
    enable-normalization-flatten-containers = false;
    enable-normalization-opposite-orientation-for-nested-containers = false;

    default-root-container-layout = "tiles";
    default-root-container-orientation = "auto";

    gaps = {
      outer.top = [
        { monitor = { "BenQ GW2480.*1" = 38; }; }
        { monitor = { "BenQ GW2480.*2" = 38; }; }
        { monitor = { "LG HDR 4K" = 38; }; }
        { monitor = { "LG HDR WQHD" = 38; }; }
        { monitor = { "LG UltraFine" = 38; }; } 
        0
      ];
    };

    exec-on-workspace-change = [
      "/bin/bash" "-c"
      "/opt/homebrew/bin/sketchybar --trigger aerospace_workspace_change FOCUSED_WORKSPACE=$AEROSPACE_FOCUSED_WORKSPACE PREV_WORKSPACE=$AEROSPACE_PREV_WORKSPACE"
    ];

    on-window-detected = [
      {
        run = "layout tiling";
      }
    ];

    on-focused-monitor-changed = [ "move-mouse monitor-lazy-center" ];

    mode.main.binding = {
      cmd-m = [ ];

      alt-enter = "exec-and-forget /usr/bin/open -na /Applications/Alacritty.app";

      alt-h = "focus --boundaries all-monitors-outer-frame left";
      alt-j = "focus --boundaries all-monitors-outer-frame down";
      alt-k = "focus --boundaries all-monitors-outer-frame up";
      alt-l = "focus --boundaries all-monitors-outer-frame right";

      alt-shift-h = "move left";
      alt-shift-j = "move down";
      alt-shift-k = "move up";
      alt-shift-l = "move right";

      alt-shift-q = "close --quit-if-last-window";

      alt-g = "split horizontal";
      alt-v = "split vertical";

      alt-f = "fullscreen";

      alt-s = "layout v_accordion";
      alt-w = "layout h_accordion";
      alt-e = "layout tiles horizontal vertical";

      alt-shift-space = "layout floating tiling";

      alt-1 = "workspace 1";
      alt-2 = "workspace 2";
      alt-3 = "workspace 3";
      alt-4 = "workspace 4";
      alt-5 = "workspace 5";
      alt-6 = "workspace 6";
      alt-7 = "workspace 7";
      alt-8 = "workspace 8";
      alt-9 = "workspace 9";
      alt-0 = "workspace 10";

      alt-shift-1 = "move-node-to-workspace 1";
      alt-shift-2 = "move-node-to-workspace 2";
      alt-shift-3 = "move-node-to-workspace 3";
      alt-shift-4 = "move-node-to-workspace 4";
      alt-shift-5 = "move-node-to-workspace 5";
      alt-shift-6 = "move-node-to-workspace 6";
      alt-shift-7 = "move-node-to-workspace 7";
      alt-shift-8 = "move-node-to-workspace 8";
      alt-shift-9 = "move-node-to-workspace 9";
      alt-shift-0 = "move-node-to-workspace 10";

      alt-shift-c = "reload-config";

      alt-r = "mode resize";
    };

    mode.resize.binding = {
      h = "resize width -50";
      j = "resize height +50";
      k = "resize height -50";
      l = "resize width +50";
      enter = "mode main";
      esc = "mode main";
    };

    workspace-to-monitor-force-assignment = {
      "1" = 1;
      "2" = [ 2 1 ];
      "3" = [ 3 2 1 ];
      "4" = [ "2480.*1" 2 ];
      "5" = [ "2480.*2" 1 ];
      "6" = [ 3 2 1 ];
      "7" = 1;
      "8" = [ 2 1 ];
      "9" = [ 3 1 ];
      "10" = [ "2480.*1" 1 ];
    };
  };
in
{
  xdg.configFile."aerospace/aerospace.toml".source =
    tomlFormat.generate "aerospace.toml" aerospaceConfig;
}
