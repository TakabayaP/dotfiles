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
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, nix-darwin, nixvim, ... }: {
    darwinConfigurations."macbook-pro" = nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      modules = [
        ./hosts/macbook-pro/system.nix
        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { username = "katsumi.kobayashi"; };
          home-manager.users."katsumi.kobayashi" = {
            imports = [
              nixvim.homeModules.nixvim
              ./hosts/macbook-pro/default.nix
            ];
            home.stateVersion = "24.11";
            programs.home-manager.enable = true;
          };
        }
      ];
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
