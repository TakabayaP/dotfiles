{ username, ... }:
{
  home.username = username;
  home.homeDirectory = "/Users/${username}";

  imports = [ ../../modules/darwin/default.nix ];
}
