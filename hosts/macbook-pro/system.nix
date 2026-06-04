{ pkgs, ... }:
{
  nixpkgs.hostPlatform = "aarch64-darwin";

  users.users."katsumi.kobayashi" = {
    home = "/Users/katsumi.kobayashi";
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
      "sketchybar"
    ];
    onActivation = {
      autoUpdate = true;
      cleanup = "none";
    };
  };

  system.primaryUser = "katsumi.kobayashi";

  nix.enable = false;

  system.stateVersion = 6;
}
