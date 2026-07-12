{ pkgs, ... }:
let
  catppuccinGtk = pkgs.catppuccin-gtk.override {
    accents = [ "sapphire" ];
    size = "compact";
    variant = "mocha";
  };

  gtkMenuCss = ''
    /* Keep native context menus compact, including GTK-backed Electron menus. */
    menu menuitem,
    .context-menu menuitem,
    popover.menu modelbutton,
    popover.background modelbutton {
      min-height: 0;
      min-width: 0;
      padding: 3px 8px;
    }

    menu separator,
    popover.menu separator {
      min-height: 1px;
      margin: 3px 6px;
    }
  '';

  notionWithoutMenu = pkgs.writeShellScriptBin "notion-app" ''
    source_asar=/usr/lib/notion-app/app.asar
    source_unpacked=/usr/lib/notion-app/app.asar.unpacked
    electron=/usr/bin/electron41
    asar=/usr/bin/asar

    if [[ ! -r "$source_asar" || ! -x "$electron" || ! -x "$asar" ]]; then
      echo "notion-app: notion-app-electron, electron41, and asar must be installed" >&2
      exit 127
    fi

    cache_dir="''${XDG_CACHE_HOME:-$HOME/.cache}/notion-app-no-menu"
    patched_asar="$cache_dir/app.asar"
    source_hash="$(${pkgs.coreutils}/bin/sha256sum "$source_asar" | ${pkgs.coreutils}/bin/cut -d ' ' -f 1)"
    patch_key="$source_hash-keep-menu-accelerators-v2"

    if [[ ! -r "$patched_asar" || ! -r "$cache_dir/source.sha256" ]] \
      || [[ "$(<"$cache_dir/source.sha256")" != "$patch_key" ]]; then
      ${pkgs.coreutils}/bin/mkdir -p "$cache_dir"
      work_dir="$(${pkgs.coreutils}/bin/mktemp -d "$cache_dir/build.XXXXXX")"
      trap '${pkgs.coreutils}/bin/rm -rf "$work_dir"' EXIT

      "$asar" extract "$source_asar" "$work_dir/app"
      main_js="$work_dir/app/.webpack/main/index.js"
      if [[ ! -f "$main_js" ]]; then
        echo "notion-app: .webpack/main/index.js was not found in app.asar" >&2
        exit 1
      fi

      # Retain Notion's application menu because Electron implements shortcuts
      # such as Ctrl+Tab through its menu accelerators. Hide only the visual menu
      # bar, and disable Electron's usual single-Alt reveal behavior.
      ${pkgs.gnused}/bin/sed -i '1i (()=>{const{app,BrowserWindow,Menu}=require("electron"),hide=w=>{w.setAutoHideMenuBar(false);w.setMenuBarVisibility(false)},set=Menu.setApplicationMenu.bind(Menu);app.on("browser-window-created",(_,w)=>hide(w));Menu.setApplicationMenu=m=>{set(m);BrowserWindow.getAllWindows().forEach(hide)}})();' "$main_js"
      "$asar" pack "$work_dir/app" "$work_dir/app.asar"
      ${pkgs.coreutils}/bin/mv "$work_dir/app.asar" "$patched_asar"
      ${pkgs.coreutils}/bin/ln -sfn "$source_unpacked" "$cache_dir/app.asar.unpacked"
      printf '%s\n' "$patch_key" > "$cache_dir/source.sha256"
      ${pkgs.coreutils}/bin/rm -rf "$work_dir"
      trap - EXIT
    fi

    if [[ "''${1:-}" == "--prepare-menu-patch" ]]; then
      printf '%s\n' "$patched_asar"
      exit 0
    fi

    notion_user_flags=""
    notion_flags="''${XDG_CONFIG_HOME:-$HOME/.config}/notion-flags.conf"
    if [[ -f "$notion_flags" ]]; then
      notion_user_flags="$(${pkgs.gnugrep}/bin/grep -v '^#' "$notion_flags")"
    fi

    cd /usr/lib/notion-app
    exec "$electron" "$patched_asar" $notion_user_flags "$@"
  '';
in
{
  home.packages = [ notionWithoutMenu ];

  gtk = {
    enable = true;
    colorScheme = "dark";
    font = {
      name = "Cantarell";
      size = 10;
    };
    theme = {
      name = "catppuccin-mocha-sapphire-compact";
      package = catppuccinGtk;
    };
    iconTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };
    cursorTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };
    gtk3.extraCss = gtkMenuCss;
    gtk4 = {
      theme = {
        name = "catppuccin-mocha-sapphire-compact";
        package = catppuccinGtk;
      };
      extraCss = gtkMenuCss;
    };
  };

  # Keep xfce4-notifyd rather than dunst, but use notifyd's original defaults.
  xfconf.settings.xfce4-notifyd = {
    theme = null;
    "min-width-enabled" = null;
    "min-width" = null;
    "initial-opacity" = null;
  };

  # Notifications previously used Adwaita-dark. Keep that appearance isolated
  # from the compact Catppuccin theme used by application context menus.
  systemd.user.services.xfce4-notifyd.Service.Environment = "GTK_THEME=Adwaita-dark";
}
