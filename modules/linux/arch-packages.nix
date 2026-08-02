{ lib, pkgs, ... }:
let
  archPackages = [
    # Host-side GUI programs share Arch's glibc and graphics runtime with the
    # installed driver.
    "kitty"
    "mpv"
  ];

  archPackageManifest = pkgs.writeText "arch-packages.txt" ''
    # Packages managed by pacman for this dotfiles configuration.
    # Home Manager does not install or update these automatically.
    ${lib.concatStringsSep "\n" archPackages}
  '';

  syncArchPackages = pkgs.writeShellApplication {
    name = "sync-arch-packages";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      manifest="$HOME/.config/dotfiles/arch-packages.txt"

      if [ ! -f "$manifest" ]; then
        echo "sync-arch-packages: manifest not found: $manifest" >&2
        echo "Run home-manager switch first." >&2
        exit 1
      fi

      if ! command -v pacman >/dev/null 2>&1; then
        echo "sync-arch-packages: pacman is not available" >&2
        exit 1
      fi

      mapfile -t packages < <(
        sed \
          -e 's/[[:space:]]*#.*$//' \
          -e '/^[[:space:]]*$/d' \
          "$manifest"
      )

      if [ "''${#packages[@]}" -eq 0 ]; then
        echo "sync-arch-packages: no packages listed"
        exit 0
      fi

      echo "Requesting pacman to install or update: ''${packages[*]}"
      exec sudo pacman -S --needed "''${packages[@]}"
    '';
  };
in
{
  home.packages = [ syncArchPackages ];
  xdg.configFile."dotfiles/arch-packages.txt".source = archPackageManifest;
}
