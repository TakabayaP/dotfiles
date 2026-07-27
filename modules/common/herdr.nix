{ pkgs, herdr, ... }:
{
  home.packages = [
    herdr.packages.${pkgs.system}.default
  ];

  xdg.configFile."herdr/config.toml".text = ''
    onboarding = false

    [terminal]
    shell_mode = "auto"
    new_cwd = "follow"

    [update]
    # Herdr itself is updated by changing the pinned Flake input.
    version_check = false

    [keys]
    prefix = "ctrl+space"

    # prefix+s is used for a horizontal split, as in the tmux config.
    settings = "prefix+shift+s"

    split_vertical = "prefix+v"
    split_horizontal = "prefix+s"

    # Accept both releasing Ctrl after the prefix and keeping it held.
    focus_pane_left = ["prefix+h", "prefix+ctrl+h"]
    focus_pane_down = ["prefix+j", "prefix+ctrl+j"]
    focus_pane_up = ["prefix+k", "prefix+ctrl+k"]
    focus_pane_right = ["prefix+l", "prefix+ctrl+l"]

    new_tab = "prefix+c"
    switch_tab = ["prefix+1..9", "prefix+ctrl+1..9"]
    switch_workspace = ["prefix+shift+1..9", "prefix+ctrl+shift+1..9"]
    open_notification_target = "prefix+o"
    zoom = "prefix+f"

    [ui]
    mouse_capture = true
    copy_on_select = true

    # open_notification_target can jump only while the notification is visible.
    [ui.toast]
    delivery = "herdr"
    delay_seconds = 1
  '';
}
