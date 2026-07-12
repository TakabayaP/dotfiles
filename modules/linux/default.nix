{ hostConfig, pkgs, ... }:
let
  startAltTapInput = pkgs.writeShellScriptBin "start-alt-tap-input" ''
    ${pkgs.procps}/bin/pkill -x xcape 2>/dev/null || true
    exec ${pkgs.xcape}/bin/xcape -e 'Alt_L=Muhenkan;Alt_R=Henkan_Mode'
  '';

  startXfce4Notifyd = pkgs.writeShellScriptBin "start-xfce4-notifyd" ''
    systemctl --user stop dunst.service 2>/dev/null || true
    systemctl --user start xfce4-notifyd.service 2>/dev/null && exit 0
    pkill -x dunst 2>/dev/null || true
    exec ${pkgs.xfce4-notifyd}/lib/xfce4/notifyd/xfce4-notifyd
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
    ./desktop-ui.nix
  ];

  home.packages = [
    pkgs.xfce4-notifyd
    pkgs.xcape
    startAltTapInput
    startXfce4Notifyd
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

  systemd.user.services.xfce4-notifyd = {
    Unit = {
      Description = "XFCE notification daemon";
      Conflicts = [ "dunst.service" ];
    };

    Service = {
      Type = "simple";
      ExecStart = "${pkgs.xfce4-notifyd}/lib/xfce4/notifyd/xfce4-notifyd";
    };

    Install.WantedBy = [ "graphical-session.target" ];
  };
}
