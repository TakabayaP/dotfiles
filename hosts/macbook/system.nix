{ lib, username, ... }:
let
  # Preserve the current System Settings modifier layout for each known
  # keyboard. These are HID usage IDs, not hardware scan codes.
  modifierMappings = {
    "com.apple.keyboard.modifiermapping.0-0-0" = [
      { HIDKeyboardModifierMappingSrc = 30064771303; HIDKeyboardModifierMappingDst = 30064771300; }
      { HIDKeyboardModifierMappingSrc = 30064771302; HIDKeyboardModifierMappingDst = 30064771303; }
      { HIDKeyboardModifierMappingSrc = 30064771129; HIDKeyboardModifierMappingDst = 30064771303; }
      { HIDKeyboardModifierMappingSrc = 30064771299; HIDKeyboardModifierMappingDst = 30064771296; }
      { HIDKeyboardModifierMappingSrc = 30064771296; HIDKeyboardModifierMappingDst = 30064771298; }
      { HIDKeyboardModifierMappingSrc = 30064771300; HIDKeyboardModifierMappingDst = 30064771302; }
      { HIDKeyboardModifierMappingSrc = 30064771298; HIDKeyboardModifierMappingDst = 30064771299; }
    ];
    "com.apple.keyboard.modifiermapping.1278-33-0" = [
      { HIDKeyboardModifierMappingSrc = 30064771300; HIDKeyboardModifierMappingDst = 30064771303; }
      { HIDKeyboardModifierMappingSrc = 30064771303; HIDKeyboardModifierMappingDst = 30064771302; }
      { HIDKeyboardModifierMappingSrc = 30064771302; HIDKeyboardModifierMappingDst = 30064771300; }
      { HIDKeyboardModifierMappingSrc = 30064771129; HIDKeyboardModifierMappingDst = 30064771303; }
      { HIDKeyboardModifierMappingSrc = 30064771296; HIDKeyboardModifierMappingDst = 30064771299; }
      { HIDKeyboardModifierMappingSrc = 30064771298; HIDKeyboardModifierMappingDst = 30064771296; }
      { HIDKeyboardModifierMappingSrc = 30064771299; HIDKeyboardModifierMappingDst = 30064771298; }
    ];
    "com.apple.keyboard.modifiermapping.1452-591-0" = [
      { HIDKeyboardModifierMappingSrc = 30064771298; HIDKeyboardModifierMappingDst = 30064771296; }
      { HIDKeyboardModifierMappingSrc = 30064771303; HIDKeyboardModifierMappingDst = 30064771302; }
      { HIDKeyboardModifierMappingSrc = 30064771300; HIDKeyboardModifierMappingDst = 30064771303; }
      { HIDKeyboardModifierMappingSrc = 30064771299; HIDKeyboardModifierMappingDst = 30064771298; }
      { HIDKeyboardModifierMappingSrc = 30064771296; HIDKeyboardModifierMappingDst = 30064771299; }
      { HIDKeyboardModifierMappingSrc = 30064771302; HIDKeyboardModifierMappingDst = 30064771300; }
      { HIDKeyboardModifierMappingSrc = 30064771129; HIDKeyboardModifierMappingDst = 30064771303; }
    ];
  };

  writeModifierMappings = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (
      mappingKey: mappings: ''
        /bin/launchctl asuser "$primary_uid" \
          /usr/bin/sudo --user=${lib.escapeShellArg username} -- \
          /usr/bin/defaults -currentHost write -g ${lib.escapeShellArg mappingKey} \
            ${lib.escapeShellArg (lib.generators.toPlist { escape = true; } mappings)}
      ''
    ) modifierMappings
  );
in
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
      "kitty"
      "nikitabobko/tap/aerospace"
      "font-hack-nerd-font"
      "macskk"
      "1password-cli"
      "cloudflare-warp"
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
    # Kitty is a signed Homebrew cask and has no quarantine attribute. Recursively
    # removing attributes from its signed frameworks is rejected by macOS.
    for app in AeroSpace Alacritty; do
      if [ -d "/Applications/$app.app" ]; then
        /usr/bin/xattr -dr com.apple.quarantine "/Applications/$app.app"
      fi
    done

    # System Settings stores custom mappings per keyboard in the current-host
    # global domain. Remove stale entries, then restore the captured mappings.
    primary_uid=$(/usr/bin/id -u ${lib.escapeShellArg username})
    /bin/launchctl asuser "$primary_uid" \
      /usr/bin/sudo --user=${lib.escapeShellArg username} -- \
      /usr/bin/defaults -currentHost read -g 2>/dev/null |
      /usr/bin/awk -F '"' '/com[.]apple[.]keyboard[.]modifiermapping[.]/ { print $2 }' |
      while IFS= read -r mapping_key; do
        /bin/launchctl asuser "$primary_uid" \
          /usr/bin/sudo --user=${lib.escapeShellArg username} -- \
          /usr/bin/defaults -currentHost delete -g "$mapping_key" || true
      done

    ${writeModifierMappings}

    # After Keykun swaps terminal modifiers, Herdr receives the current physical
    # shortcut as Command-Space. Disable Spotlight so it reaches the terminal.
    /bin/launchctl asuser "$primary_uid" \
      /usr/bin/sudo --user=${lib.escapeShellArg username} -- \
      /usr/bin/defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys \
        -dict-add 64 '<dict><key>enabled</key><false/></dict>'

    # Reload the per-user preferences daemon after updating keyboard settings.
    /bin/launchctl asuser "$primary_uid" \
      /usr/bin/sudo --user=${lib.escapeShellArg username} -- \
      /usr/bin/killall cfprefsd || true
  '';

  system.primaryUser = username;

  # Clear any separate hidutil overlay; per-device mappings are managed above.
  system.keyboard.enableKeyMapping = true;

  system.defaults = {
    NSGlobalDomain = {
      _HIHideMenuBar = true;
      InitialKeyRepeat = 25;
      KeyRepeat = 5;
    };

    CustomUserPreferences = {
      ".GlobalPreferences"."com.apple.mouse.scaling" = lib.mkForce (-1);

      # macSKK handles this only while its input source is active. Keeping it
      # here avoids a machine-wide Cmd+J rewrite in Keykun.
      "net.mtgto.inputmethod.macSKK" = {
        selectedKeyBindingSetId = "dotfiles";
        keyBindingSets = [
          {
            id = "dotfiles";
            version = 1;
            keyBindings = [
              {
                action = "hiragana";
                inputs = [
                  {
                    key = "j";
                    # NSEvent.ModifierFlags.command.rawValue
                    modifierFlags = 1048576;
                    optionalModifierFlags = 0;
                  }
                ];
              }
            ];
          }
        ];
      };
    };
  };

  security.pam.services.sudo_local = {
    touchIdAuth = true;
    reattach = true;
  };

  nix.enable = false;

  system.stateVersion = 6;
}
