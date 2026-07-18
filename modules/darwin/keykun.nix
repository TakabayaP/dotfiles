{ config, lib, pkgs, keykunSrc, ... }:

let
  keykun = pkgs.callPackage ./keykun-package.nix {
    inherit keykunSrc;
  };

  keykunApp = "${keykun}/Applications/Keykun.app";

  # Keep the settings that are currently used on the primary Mac declarative.
  # The activation script copies this into Application Support as a regular,
  # writable file so Keykun can still update it from its UI.
  keykunSettings = pkgs.writeText "keykun-settings.json" (builtins.toJSON {
    inputSwitch = {
      isEnabled = true;
      leftAction = "eisu";
      rightAction = "kana";
      tapThreshold = 0.3;
      targetModifier = "control";
    };
    slackEscape = {
      isEnabled = true;
    };
  });

  installedApp = "${config.home.homeDirectory}/Applications/Keykun.app";
in
{
  # Home Manager exposes the package in the user profile and maintains a
  # stable app path for Accessibility/TCC and LaunchServices.
  home.packages = [ keykun ];
  home.file."Applications/Keykun.app".source = keykunApp;

  home.activation.keykunSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    settings_dir="$HOME/Library/Application Support/Keykun"
    settings_file="$settings_dir/settings.json"
    mkdir -p "$settings_dir"

    if [ ! -f "$settings_file" ] || ! cmp -s "$settings_file" "${keykunSettings}"; then
      install -m 0644 "${keykunSettings}" "$settings_file.tmp"
      mv "$settings_file.tmp" "$settings_file"
    fi
  '';

  # Keep the menu-bar app running at login without requiring a privileged
  # install step. Accessibility approval remains a one-time user action.
  launchd.agents.keykun = {
    enable = true;
    config = {
      Label = "com.mtkg.keykun.nix";
      ProgramArguments = [ "${installedApp}/Contents/MacOS/Keykun" ];
      RunAtLoad = true;
      KeepAlive = true;
      ProcessType = "Interactive";
      LimitLoadToSessionType = "Aqua";
      StandardOutPath = "/tmp/keykun.out.log";
      StandardErrorPath = "/tmp/keykun.err.log";
    };
  };
}
