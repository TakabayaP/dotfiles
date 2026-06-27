{
  description = "takabaya dotfiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    codex-desktop-linux = {
      url = "github:ilysenko/codex-desktop-linux";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    liveWallpaperSrc = {
      url = "git+ssh://git@github.com/TakabayaP/live-wallpaper.git?ref=release-build-without-previews&rev=b52c85ce8bf826f57d073343aea25f59c29d9dd1";
      flake = false;
    };
  };

  outputs = { nixpkgs, home-manager, nix-darwin, nix-homebrew, nixvim, codex-desktop-linux, liveWallpaperSrc, ... }:
    let
      mkDarwinConfiguration = username: nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = { inherit username liveWallpaperSrc; };
        modules = [
          ./hosts/macbook/system.nix
          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              enable = true;
              user = username;
              autoMigrate = true;
            };
          }
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit username liveWallpaperSrc; };
            home-manager.users.${username} = {
              imports = [
                nixvim.homeModules.nixvim
                ./hosts/macbook/default.nix
              ];
              home.stateVersion = "24.11";
              programs.home-manager.enable = true;
            };
          }
        ];
      };
      mkLinuxHomeConfiguration = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs { system = "x86_64-linux"; };
        extraSpecialArgs = { username = "takabaya"; };
        modules = [
          nixvim.homeModules.nixvim
          codex-desktop-linux.homeManagerModules.default
          ./hosts/takabayap-H1-arch/default.nix
          ({ pkgs, ... }: {
            home.stateVersion = "24.11";
            programs.home-manager.enable = true;
            programs.codexDesktopLinux = {
              enable = true;
              cliPackage = pkgs.codex;
            };
          })
        ];
      };
    in {
    darwinConfigurations = {
      macbook-pro = mkDarwinConfiguration "katsumi.kobayashi";
      macbook-air = mkDarwinConfiguration "katsumikobayashi";
    };

    homeConfigurations = {
      "takabaya@takabayap-H1-arch" = mkLinuxHomeConfiguration;
      "takabaya@takabayap-H1-arch-i3" = mkLinuxHomeConfiguration;
    };
  };
}
