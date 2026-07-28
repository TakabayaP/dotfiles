{ pkgs, herdr, ... }:
let
  herdrPackage = herdr.packages.${pkgs.system}.default;
  herdrWithNvimEditor = pkgs.writeShellScriptBin "herdr" ''
    export EDITOR=nvim
    # Herdr renders Kitty graphics locally, so let Neovim image plugins use
    # Kitty placeholders inside managed panes.
    export SNACKS_KITTY=true
    exec ${herdrPackage}/bin/herdr "$@"
  '';
in
{
  home.packages = [
    herdrWithNvimEditor
  ];

  xdg.configFile."herdr/config.toml".text = ''
    onboarding = false

    [terminal]
    shell_mode = "auto"
    new_cwd = "follow"

    [update]
    # Herdr itself is updated by changing the pinned Flake input.
    version_check = false

    [experimental]
    # Render Kitty Graphics Protocol images emitted by applications in panes.
    kitty_graphics = true

    [keys]
    prefix = "ctrl+space"

    # prefix+s is used for a horizontal split, as in the tmux config.
    settings = "prefix+shift+s"

    split_vertical = ["prefix+v", "prefix+ctrl+v"]
    split_horizontal = ["prefix+s", "prefix+ctrl+s"]

    # Accept both releasing Ctrl after the prefix and keeping it held.
    focus_pane_left = ["prefix+h", "prefix+ctrl+h"]
    focus_pane_down = ["prefix+j", "prefix+ctrl+j"]
    focus_pane_up = ["prefix+k", "prefix+ctrl+k"]
    focus_pane_right = ["prefix+l", "prefix+ctrl+l"]

    new_tab = "prefix+c"
    switch_tab = ["prefix+1..9", "prefix+ctrl+1..9"]
    switch_workspace = ["prefix+shift+1..9", "prefix+ctrl+shift+1..9"]
    open_notification_target = "prefix+o"
    zoom = ["prefix+f", "prefix+ctrl+f"]
    toggle_sidebar = ["prefix+b", "prefix+ctrl+b"]

    [ui]
    mouse_capture = true
    copy_on_select = true

    # open_notification_target can jump only while the notification is visible.
    [ui.toast]
    delivery = "herdr"
    delay_seconds = 1
  '';
}
