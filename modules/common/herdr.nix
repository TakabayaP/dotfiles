{ config, lib, pkgs, herdr, ... }:
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

  # Keep the Herdr skill available to both Codex CLI and Cursor CLI. Copy the
  # pinned source instead of linking into the Nix store so CLI skill discovery
  # sees a regular SKILL.md in each tool's user skill directory.
  home.activation.installHerdrSkills =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      skill_source="${herdr.outPath}/SKILL.md"
      for skill_target in \
        "${config.home.homeDirectory}/.agents/skills/herdr/SKILL.md" \
        "${config.home.homeDirectory}/.cursor/skills/herdr/SKILL.md"; do
        target_dir="$(dirname "$skill_target")"
        $DRY_RUN_CMD mkdir -p "$target_dir"
        if [ ! -f "$skill_target" ] || ! cmp -s "$skill_source" "$skill_target"; then
          skill_tmp="$target_dir/.SKILL.md.tmp"
          $DRY_RUN_CMD install -m 0644 "$skill_source" "$skill_tmp"
          $DRY_RUN_CMD mv -f "$skill_tmp" "$skill_target"
        fi
        $DRY_RUN_CMD chmod 0644 "$skill_target"
      done
    '';

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
    # Keykun swaps Command and Control in macOS terminal apps. Using
    # Command-Space here therefore keeps the current physical shortcut
    # (the key beside Space + Space). Linux uses Alt-Space for the same
    # easy-to-reach physical chord without conflicting with i3's Mod4-Space.
    prefix = "${if pkgs.stdenv.isDarwin then "cmd+space" else "alt+space"}"

    # prefix+s is used for a horizontal split, as in the tmux config.
    settings = "prefix+shift+s"

    split_vertical = ["prefix+v", "prefix+ctrl+v"]
    split_horizontal = ["prefix+s", "prefix+ctrl+s"]

    # Keep the Ctrl-modified aliases as well. Command-modified action keys
    # conflict with existing macOS shortcuts such as Cmd+H.
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
