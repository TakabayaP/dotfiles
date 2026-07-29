{ lib, pkgs, liveWallpaperSrc, ... }:
let
  optimizeWallpaperVideo = pkgs.writeShellApplication {
    name = "optimize-wallpaper-video";
    runtimeInputs = [ pkgs.ffmpeg ];
    text = ''
      if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
        echo "Usage: optimize-wallpaper-video INPUT [OUTPUT]" >&2
        exit 2
      fi

      input="$1"
      output="''${2:-''${input%.*}-wallpaper-60fps.mov}"

      if [ ! -f "$input" ]; then
        echo "Input file not found: $input" >&2
        exit 1
      fi

      if [ -e "$output" ]; then
        echo "Output already exists: $output" >&2
        exit 1
      fi

      ffmpeg \
        -hide_banner \
        -nostdin \
        -i "$input" \
        -map 0:v:0 \
        -an \
        -sn \
        -dn \
        -vf "fps=60" \
        -c:v hevc_videotoolbox \
        -allow_sw 1 \
        -b:v 8M \
        -pix_fmt yuv420p \
        -tag:v hvc1 \
        -movflags +faststart \
        "$output"

      echo "Created: $output"
    '';
  };

  liveWallpaper = pkgs.stdenvNoCC.mkDerivation {
    pname = "live-wallpaper";
    version = "1.1.0-02f15e1";

    src = liveWallpaperSrc;

    dontConfigure = true;
    dontFixup = true;

    __noChroot = true;

    buildPhase = ''
      runHook preBuild

      export HOME="$TMPDIR"
      export SYMROOT="$TMPDIR/build"

      /usr/bin/xcrun xcodebuild \
        -project LiveWallpaper.xcodeproj \
        -scheme LiveWallpaper \
        -configuration Release \
        -derivedDataPath "$TMPDIR/DerivedData" \
        SYMROOT="$SYMROOT" \
        CODE_SIGNING_ALLOWED=NO \
        CODE_SIGNING_REQUIRED=NO \
        CODE_SIGN_IDENTITY= \
        build

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p "$out/Applications"
      cp -R "$SYMROOT/Release/LiveWallpaper.app" "$out/Applications/"

      runHook postInstall
    '';

    meta = {
      description = "Set videos as the desktop wallpaper on macOS";
      homepage = "https://github.com/TakabayaP/live-wallpaper";
      license = lib.licenses.mit;
      platforms = lib.platforms.darwin;
    };
  };
in
{
  home.packages = [
    liveWallpaper
    optimizeWallpaperVideo
  ];
  home.file.".local/bin/optimize-wallpaper-video".source =
    "${optimizeWallpaperVideo}/bin/optimize-wallpaper-video";

  launchd.agents.live-wallpaper = {
    enable = true;
    config = {
      Label = "com.baonguyen.LiveWallpaper.keepalive";
      ProgramArguments = [
        "${liveWallpaper}/Applications/LiveWallpaper.app/Contents/MacOS/LiveWallpaper"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/livewallpaper.out.log";
      StandardErrorPath = "/tmp/livewallpaper.err.log";
    };
  };
}
