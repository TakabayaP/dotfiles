{ hostConfig, ... }:
let
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
  xsession.enable = true;
  xsession.windowManager.i3 = {
    enable = true;
    config = null;
    extraConfig = i3Config;
  };
}
