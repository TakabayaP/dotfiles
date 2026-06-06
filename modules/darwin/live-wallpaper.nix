{ lib, pkgs, liveWallpaperSrc, ... }:
let
  liveWallpaper = pkgs.stdenvNoCC.mkDerivation {
    pname = "live-wallpaper";
    version = "1.1.0-b52c85c";

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
  ];

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
