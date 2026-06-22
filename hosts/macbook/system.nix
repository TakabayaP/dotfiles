{ lib, username, ... }:
{
  nixpkgs.hostPlatform = "aarch64-darwin";

  users.users.${username} = {
    home = "/Users/${username}";
  };

  homebrew = {
    enable = true;
    taps = [
      "nikitabobko/tap"
      "FelixKratz/formulae"
    ];
    casks = [
      "alacritty"
      "nikitabobko/tap/aerospace"
      "font-hack-nerd-font"
      "macskk"
      "1password-cli"
      "gcloud-cli"
      "orbstack"
    ];
    brews = [
      "fish"
      {
        name = "sketchybar";
        start_service = true;
      }
    ];
    onActivation = {
      autoUpdate = true;
      cleanup = "none";
    };
  };

  system.activationScripts.postActivation.text = ''
    for app in AeroSpace Alacritty; do
      if [ -d "/Applications/$app.app" ]; then
        /usr/bin/xattr -dr com.apple.quarantine "/Applications/$app.app"
      fi
    done
  '';

  system.primaryUser = username;

  system.defaults = {
    NSGlobalDomain = {
      _HIHideMenuBar = true;
      InitialKeyRepeat = 10;
      KeyRepeat = 1;
    };

    CustomUserPreferences.".GlobalPreferences"."com.apple.mouse.scaling" = lib.mkForce (-1);
  };

  security.pam.services.sudo_local = {
    touchIdAuth = true;
    reattach = true;
  };

  nix.enable = false;

  system.stateVersion = 6;
}
