{ lib, stdenvNoCC, keykunSrc }:

stdenvNoCC.mkDerivation {
  pname = "keykun";
  version = "1.4.5";
  src = keykunSrc;

  dontConfigure = true;
  dontFixup = true;

  postPatch = ''
    substituteInPlace Scripts/bundle.sh \
      --replace-fail 'swift build -c' 'swift build --disable-sandbox -c'
  '';

  # Keykun is an AppKit/SwiftPM application. Its build uses the Apple
  # developer tools and codesign, just like the existing Xcode app build in
  # this repository.
  __noChroot = true;

  buildPhase = ''
    runHook preBuild

    export HOME="$TMPDIR/home"
    export XDG_CACHE_HOME="$TMPDIR/cache"
    export PATH="/usr/bin:/bin:$PATH"
    mkdir -p "$HOME" "$XDG_CACHE_HOME"

    AD_HOC=1 bash Scripts/bundle.sh release

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/Applications"
    cp -R Keykun.app "$out/Applications/Keykun.app"

    runHook postInstall
  '';

  meta = {
    description = "Personal macOS menu bar app for input switching";
    homepage = "https://github.com/TakabayaP/keykun";
    license = lib.licenses.mit;
    platforms = lib.platforms.darwin;
    mainProgram = "Keykun";
  };
}
