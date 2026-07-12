{ lib, pkgs, ... }:
let
  patchedFcitx5Skk = pkgs.qt6Packages.fcitx5-skk-qt.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      ../../patches/fcitx5-skk-reset-input-mode-on-activate.patch
    ];
  });

  fcitx5WithAddons = pkgs.qt6Packages.fcitx5-with-addons.override {
    addons = [ patchedFcitx5Skk ];
  };

  startFcitx5 = pkgs.writeShellScriptBin "start-fcitx5" ''
    export FCITX_ADDON_DIRS=${fcitx5WithAddons}/lib/fcitx5
    export XDG_DATA_DIRS=${fcitx5WithAddons}/share
    exec ${fcitx5WithAddons}/bin/fcitx5
  '';

  activateFcitx5 = pkgs.writeShellScriptBin "activate-fcitx5" ''
    exec ${fcitx5WithAddons}/bin/fcitx5-remote -o
  '';

  deactivateFcitx5 = pkgs.writeShellScriptBin "deactivate-fcitx5" ''
    exec ${fcitx5WithAddons}/bin/fcitx5-remote -c
  '';

  customKeymaps = {
    default = {
      include = [ "default/default" ];
      define.keymap."\\" = null;
    };
    hiragana = {
      include = [ "default/hiragana" ];
      define.keymap = {
        "C-q" = null;
        "C-j" = null;
        "A-q" = "set-input-mode-hankaku-katakana";
        "A-j" = "commit";
      };
    };
    katakana = {
      include = [ "default/katakana" ];
      define.keymap = {
        "C-q" = null;
        "C-j" = null;
        "A-q" = "set-input-mode-hankaku-katakana";
        "A-j" = "commit";
      };
    };
    hankaku-katakana = {
      include = [ "default/hankaku-katakana" ];
      define.keymap = {
        "C-q" = null;
        "C-j" = null;
        "A-q" = "set-input-mode-hiragana";
        "A-j" = "commit";
      };
    };
    latin = {
      include = [ "default/latin" ];
      define.keymap = {
        "C-j" = null;
        "A-j" = "set-input-mode-hiragana";
      };
    };
    wide-latin = {
      include = [ "default/wide-latin" ];
      define.keymap = {
        "C-j" = null;
        "A-j" = "set-input-mode-hiragana";
      };
    };
  };
in
{
  home.packages = [
    fcitx5WithAddons
    startFcitx5
    activateFcitx5
    deactivateFcitx5
  ];

  xdg.configFile = {
    "autostart/org.fcitx.Fcitx5.desktop" = {
      text = ''
        [Desktop Entry]
        Hidden=true
      '';
      force = true;
    };

    "fcitx5/config" = {
      source = ../../dotfiles/fcitx5/config;
      force = true;
    };

    "fcitx5/conf/skk.conf" = {
      source = ../../dotfiles/fcitx5/skk.conf;
      force = true;
    };

    "fcitx5/profile" = {
      source = ../../dotfiles/fcitx5/profile;
      force = true;
    };

    "fcitx5/conf/hangul.conf" = {
      source = ../../dotfiles/fcitx5/hangul.conf;
      force = true;
    };

    "fcitx5/conf/notifications.conf" = {
      source = ../../dotfiles/fcitx5/notifications.conf;
      force = true;
    };

    "libskk/rules/nix-custom/metadata.json".text = builtins.toJSON {
      name = "Nix Custom";
      description = "Custom typing rule managed by Home Manager";
    };

    "libskk/rules/nix-custom/rom-kana/default.json".text =
      builtins.toJSON { include = [ "default/default" ]; };
  } // lib.mapAttrs' (name: value:
    lib.nameValuePair "libskk/rules/nix-custom/keymap/${name}.json" {
      text = builtins.toJSON value;
    }
  ) customKeymaps;
}
