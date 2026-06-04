{ ... }:
{
  launchd.agents.live-wallpaper = {
    enable = true;
    config = {
      Label = "com.baonguyen.LiveWallpaper.keepalive";
      ProgramArguments = [
        "/Applications/LiveWallpaper.app/Contents/MacOS/LiveWallpaper"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/livewallpaper.out.log";
      StandardErrorPath = "/tmp/livewallpaper.err.log";
    };
  };
}
