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
  herdrBin = "${herdrPackage}/bin/herdr";
  homeDir = config.home.homeDirectory;
  # Official integrations report native session references that Herdr uses to
  # resume agent conversations after a server restart. Install only when the
  # agent config directory already exists so unused CLIs are left alone.
  syncHerdrIntegrations = pkgs.writeShellScriptBin "sync-herdr-integrations" ''
    set -euo pipefail

    herdr_bin=${lib.escapeShellArg herdrBin}
    home_dir=${lib.escapeShellArg homeDir}

    install_if_present() {
      target="$1"
      dir="$2"
      if [ ! -d "$dir" ]; then
        return 0
      fi
      if ! "$herdr_bin" integration install "$target"; then
        echo "sync-herdr-integrations: failed to install $target" >&2
      fi
    }

    install_if_present pi "$home_dir/.pi/agent"
    install_if_present omp "$home_dir/.omp/agent"
    install_if_present claude "$home_dir/.claude"
    install_if_present codex "$home_dir/.codex"
    install_if_present copilot "$home_dir/.copilot"
    install_if_present cursor "$home_dir/.cursor"
    install_if_present devin "$home_dir/.config/devin"
    install_if_present droid "$home_dir/.factory"
    install_if_present kimi "$home_dir/.kimi-code"
    install_if_present opencode "$home_dir/.config/opencode"
    install_if_present kilo "$home_dir/.config/kilo"
    install_if_present hermes "$home_dir/.hermes"
    install_if_present qodercli "$home_dir/.qoder"
    install_if_present mastracode "$home_dir/.mastracode"
  '';
  heldPrefixModifier = if pkgs.stdenv.isDarwin then "cmd" else "alt";
  # Keykun keeps J unchanged when macOS reports Control so macSKK can receive
  # Ctrl-J from the physical Command key. Command-origin J from Caps Lock still
  # swaps for Kitty's Neovim F19 shortcut. While the prefix modifier is held,
  # Herdr accepts the Control-J form in addition to the existing Command-J alias.
  focusPaneDownExtra = lib.optionalString pkgs.stdenv.isDarwin ", \"prefix+ctrl+j\"";
in
{
  home.packages = [ herdrWithNvimEditor syncHerdrIntegrations ];

  # gh pr create --web honors GH_BROWSER directly in both desktop sessions and
  # Herdr panes.
  home.sessionVariables.GH_BROWSER =
    if pkgs.stdenv.isDarwin then "/usr/bin/open" else "${pkgs.xdg-utils}/bin/xdg-open";

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

  home.activation.installHerdrIntegrations =
    lib.hm.dag.entryAfter [ "installHerdrSkills" "linkGeneration" ] ''
      $DRY_RUN_CMD ${syncHerdrIntegrations}/bin/sync-herdr-integrations
    '';

  home.activation.reloadHerdrConfig =
    lib.hm.dag.entryAfter [ "installHerdrIntegrations" ] ''
      if ! $DRY_RUN_CMD ${herdrBin} server reload-config; then
        echo "reloadHerdrConfig: no running Herdr server to reload" >&2
      fi
    '';

  xdg.configFile."herdr/config.toml".text = ''
    onboarding = false

    [terminal]
    shell_mode = "auto"
    new_cwd = "follow"

    [update]
    # Herdr itself is updated by changing the pinned Flake input.
    version_check = false

    [session]
    # Resume agent panes from official integration-reported session references
    # after a Herdr server restart. Integrations are installed by
    # sync-herdr-integrations when the matching agent config directory exists.
    resume_agents_on_restore = true

    [experimental]
    # Render Kitty Graphics Protocol images emitted by applications in panes.
    kitty_graphics = true
    # Restore recent pane screen contents after a full server restart.
    # Saved output lives in session-history.json and can include secrets.
    # Agent panes with native session restore skip history replay.
    pane_history = true

    [keys]
    # Keykun swaps Command and Control in macOS terminal apps. Using
    # Command-Space here therefore keeps the current physical shortcut
    # (the key beside Space + Space). Linux uses Alt-Space for the same
    # easy-to-reach physical chord without conflicting with i3's Mod4-Space.
    prefix = "${if pkgs.stdenv.isDarwin then "cmd+space" else "alt+space"}"

    # prefix+s is used for a split; keep settings on shift+s.
    settings = "prefix+shift+s"

    # Treat holding the physical prefix modifier through the action key as
    # equivalent to releasing it after prefix. Keykun makes that modifier
    # Command on macOS terminals; Linux uses Alt as the prefix modifier.
    #
    # `v` stacks panes; `s` places them side by side.
    split_vertical = ["prefix+s", "prefix+${heldPrefixModifier}+s"]
    split_horizontal = ["prefix+v", "prefix+${heldPrefixModifier}+v"]

    focus_pane_left = ["prefix+h", "prefix+${heldPrefixModifier}+h"]
    focus_pane_down = ["prefix+j", "prefix+${heldPrefixModifier}+j"${focusPaneDownExtra}]
    focus_pane_up = ["prefix+k", "prefix+${heldPrefixModifier}+k"]
    focus_pane_right = ["prefix+l", "prefix+${heldPrefixModifier}+l"]

    new_tab = "prefix+c"
    switch_tab = ["prefix+1..9", "prefix+${heldPrefixModifier}+1..9"]
    switch_workspace = ["prefix+shift+1..9", "prefix+${heldPrefixModifier}+shift+1..9"]
    open_notification_target = "prefix+o"
    zoom = ["prefix+f", "prefix+${heldPrefixModifier}+f"]
    toggle_sidebar = ["prefix+b", "prefix+${heldPrefixModifier}+b"]

    [ui]
    mouse_capture = true
    copy_on_select = true

    # open_notification_target can jump only while the notification is visible.
    [ui.toast]
    delivery = "herdr"
    delay_seconds = 1
  '';
}
