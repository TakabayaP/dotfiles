{ pkgs, ... }:
let
  napeUserspaceMouse = pkgs.buildGoModule {
    pname = "nape-userspace-mouse";
    version = "0.1.0";
    src = ../../tools/nape-userspace-mouse-go;
    vendorHash = null;
  };

  napeUserspaceMouseWrapper = pkgs.writeShellApplication {
    name = "nape-userspace-mouse";
    runtimeInputs = [
      pkgs.sudo
      pkgs.xinput
    ];
    text = ''
      xdev="Keychron Keychron Nape Pro Mouse"
      disabler_pid=""

      reenable() {
        if [ -n "$disabler_pid" ]; then
          kill "$disabler_pid" >/dev/null 2>&1 || true
        fi
        xinput enable "$xdev" >/dev/null 2>&1 || true
      }
      trap reenable EXIT INT TERM

      while true; do
        xinput disable "$xdev" >/dev/null 2>&1 || true
        sleep 2
      done &
      disabler_pid="$!"

      backend_args=()
      # Traditional scrolling is the default on both macOS and Linux.
      if [ "''${NAPE_INVERT_SCROLL:-0}" = "1" ]; then
        backend_args+=(--invert-scroll)
      fi

      if [ "''${NAPE_USE_SUDO:-0}" = "1" ]; then
        sudo_args=()
        if [ -n "''${NAPE_SUDO_FLAGS:-}" ]; then
          # shellcheck disable=SC2206
          sudo_args=(''${NAPE_SUDO_FLAGS})
        fi

        sudo "''${sudo_args[@]}" ${napeUserspaceMouse}/bin/nape-userspace-mouse "''${backend_args[@]}" "$@"
      else
        ${napeUserspaceMouse}/bin/nape-userspace-mouse "''${backend_args[@]}" "$@"
      fi
    '';
  };

  napePointerSettings = pkgs.writeShellApplication {
    name = "nape-pointer-settings";
    runtimeInputs = [ pkgs.xinput ];
    text = ''
      physical_device="Keychron Nape Pro Mouse"
      virtual_device="Nape Pro userspace mouse"

      while true; do
        for device in "$physical_device" "$virtual_device"; do
          # Match macOS's com.apple.mouse.scaling=-1: linear, unaccelerated
          # pointer motion with the hardware DPI left unchanged.
          xinput set-prop "$device" \
            "libinput Accel Profile Enabled" 0 1 \
            >/dev/null 2>&1 || true
          xinput set-prop "$device" \
            "libinput Accel Speed" 0 \
            >/dev/null 2>&1 || true

          # Use traditional scrolling on both the physical and virtual device.
          xinput set-prop "$device" \
            "libinput Natural Scrolling Enabled" 0 \
            >/dev/null 2>&1 || true
        done
        sleep 2
      done
    '';
  };
in
{
  home.packages = [
    napePointerSettings
    napeUserspaceMouseWrapper
  ];

  systemd.user.services.nape-pointer-settings = {
    Unit = {
      Description = "Match macOS pointer settings for Nape Pro mouse";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      Type = "simple";
      ExecStart = "${napePointerSettings}/bin/nape-pointer-settings";
      Restart = "on-failure";
      RestartSec = "2s";
    };

    Install.WantedBy = [ "graphical-session.target" ];
  };

  systemd.user.services.nape-userspace-mouse = {
    Unit = {
      Description = "Nape Pro userspace mouse bridge";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      Type = "simple";
      ExecStart = "${napeUserspaceMouseWrapper}/bin/nape-userspace-mouse";
      Restart = "on-failure";
      RestartSec = "2s";
    };

    Install.WantedBy = [ "graphical-session.target" ];
  };
}
