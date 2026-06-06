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
  };

  outputs = { nixpkgs, home-manager, nix-darwin, nix-homebrew, nixvim, ... }:
    let
      mkDarwinConfiguration = username: nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = { inherit username; };
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
            home-manager.extraSpecialArgs = { inherit username; };
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
    in {
    darwinConfigurations = {
      macbook-pro = mkDarwinConfiguration "katsumi.kobayashi";
      macbook-air = mkDarwinConfiguration "katsumikobayashi";
    };

    homeConfigurations."takabaya@takabayap-H1-arch-i3" =
      home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs { system = "x86_64-linux"; };
        extraSpecialArgs = { username = "takabaya"; };
        modules = [
          nixvim.homeModules.nixvim
          ./hosts/takabayap-H1-arch/default.nix
          {
            home.stateVersion = "24.11";
            programs.home-manager.enable = true;
          }
        ];
      };
  };
}
