{ pkgs, ... }:
let
  homecloudCidr = "192.168.11.0/24";
  homecloudPrefix = "192.168.11";
  warpCli = "/Applications/Cloudflare WARP.app/Contents/Resources/warp-cli";
  ensureHomecloudRoute = pkgs.writeShellScript "ensure-homecloud-warp-route" ''
    set -eu

    # Do not mistake another VPN's utun interface for Cloudflare WARP.
    if [ ! -x "${warpCli}" ]; then
      exit 0
    fi
    warp_status="$(${warpCli} status 2>/dev/null || true)"
    if ! printf '%s\n' "$warp_status" | /usr/bin/grep -q '^Status update: Connected$'; then
      exit 0
    fi
    if ! printf '%s\n' "$warp_status" | /usr/bin/grep -q '^Network: healthy$'; then
      exit 0
    fi

    # On the HomeCloud LAN, macOS's directly connected route must win.
    if /sbin/ifconfig | ${pkgs.gawk}/bin/awk \
      '$1 == "inet" && index($2, "${homecloudPrefix}.") == 1 { found = 1 } END { exit !found }'
    then
      exit 0
    fi

    warp_interface="$(${pkgs.gawk}/bin/awk \
      '$1 == "default" && $NF ~ /^utun[0-9]+$/ { print $NF; exit }' \
      < <(/usr/sbin/netstat -rn -f inet))"

    if [ -z "$warp_interface" ]; then
      exit 0
    fi

    current_interface="$(${pkgs.gawk}/bin/awk \
      '$1 == "192.168.11" || $1 == "192.168.11/24" || $1 == "192.168.11.0/24" { print $NF; exit }' \
      < <(/usr/sbin/netstat -rn -f inet))"

    if [ "$current_interface" = "$warp_interface" ]; then
      exit 0
    fi

    if [ -n "$current_interface" ]; then
      /sbin/route -n delete -net ${homecloudCidr} >/dev/null 2>&1 || true
    fi
    /sbin/route -n add -net ${homecloudCidr} -interface "$warp_interface"
  '';
in
{
  # Cloudflare WARP occasionally fails to install the private-network route on
  # macOS after reconnecting. Reconcile it without relying on the changing utun
  # interface number.
  launchd.daemons.homecloud-warp-route = {
    serviceConfig = {
      ProgramArguments = [ "${ensureHomecloudRoute}" ];
      RunAtLoad = true;
      StartInterval = 15;
      StandardOutPath = "/var/log/homecloud-warp-route.log";
      StandardErrorPath = "/var/log/homecloud-warp-route.log";
    };
  };
}
