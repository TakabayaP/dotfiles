{
  description = "takabaya dotfiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }: {
    homeConfigurations."takabaya@takabayap-H1-arch-i3" =
      home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs { system = "x86_64-linux"; };
        extraSpecialArgs = { username = "takabaya"; };
        modules = [
          ./hosts/takabayap-H1-arch/default.nix
          {
            home.stateVersion = "24.11";
            programs.home-manager.enable = true;
          }
        ];
      };

    homeConfigurations."katsumi.kobayashi@macbook-pro" =
      home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs { system = "aarch64-darwin"; };
        extraSpecialArgs = { username = "katsumi.kobayashi"; };
        modules = [
          ./hosts/macbook-pro/default.nix
          {
            home.stateVersion = "24.11";
            programs.home-manager.enable = true;
          }
        ];
      };
  };
}
