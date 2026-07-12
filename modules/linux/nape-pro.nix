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
      if [ "''${NAPE_INVERT_SCROLL:-1}" = "1" ]; then
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

  napeNaturalScroll = pkgs.writeShellApplication {
    name = "nape-natural-scroll";
    runtimeInputs = [ pkgs.xinput ];
    text = ''
      while true; do
        xinput set-prop \
          "Keychron Nape Pro Mouse" \
          "libinput Natural Scrolling Enabled" 1 \
          >/dev/null 2>&1 || true
        sleep 2
      done
    '';
  };
in
{
  home.packages = [
    napeNaturalScroll
    napeUserspaceMouseWrapper
  ];

  systemd.user.services.nape-natural-scroll = {
    Unit = {
      Description = "Enable natural scrolling for Nape Pro Bluetooth mouse";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      Type = "simple";
      ExecStart = "${napeNaturalScroll}/bin/nape-natural-scroll";
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
