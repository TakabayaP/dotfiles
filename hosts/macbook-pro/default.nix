{ username, ... }:
{
  home.username = username;
  home.homeDirectory = "/Users/${username}";

  imports = [
    ../../modules/common/default.nix
    ../../modules/darwin/default.nix
  ];
}
