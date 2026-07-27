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

    focus_pane_left = "prefix+h"
    focus_pane_down = "prefix+j"
    focus_pane_up = "prefix+k"
    focus_pane_right = "prefix+l"

    new_tab = "prefix+c"

    [ui]
    mouse_capture = true
    copy_on_select = true
  '';
}
