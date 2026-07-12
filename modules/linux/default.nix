{ hostConfig, pkgs, ... }:
let
  startAltTapInput = pkgs.writeShellScriptBin "start-alt-tap-input" ''
    ${pkgs.procps}/bin/pkill -x xcape 2>/dev/null || true
    exec ${pkgs.xcape}/bin/xcape -e 'Alt_L=Muhenkan;Alt_R=Henkan_Mode'
  '';

  i3Config = builtins.replaceStrings
    [
      "XRANDR_SCREEN_SETTING_COMMAND"
      "BACKGROUND_IMAGE_PATH"
      "#I3_WORKSPACE_NUMBER_SETTINGS"
    ]
    [
      hostConfig.xrandrCommand
      hostConfig.backgroundImage
      hostConfig.i3WorkspaceOutputs
    ]
    (builtins.readFile ../../dotfiles/i3/config);
in
{
  imports = [
    ../common/alacritty.nix
    ./alacritty.nix
    ./fcitx5.nix
  ];

  home.packages = [
    pkgs.xcape
    startAltTapInput
  ];

  home.sessionVariables = {
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
  };

  xsession.enable = true;
  xsession.windowManager.i3 = {
    enable = true;
    config = null;
    extraConfig = i3Config;
  };
}
