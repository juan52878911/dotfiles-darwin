{
  description = "Dotfiles de juanbedoya — terminal y editor reproducibles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nix-darwin, home-manager, ... }:
    let
      system = "aarch64-darwin";
      usuario = "juanbedoya";
      host = "MacBook-Pro-de-Juan";
    in {
      darwinConfigurations.${host} = nix-darwin.lib.darwinSystem {
        inherit system;
        specialArgs = { inherit usuario; };
        modules = [
          ./darwin/configuration.nix
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit usuario; };
            home-manager.users.${usuario} = import ./darwin/home.nix;
          }
        ];
      };

      # Atajo: `nix run .#switch`
      darwinPackages = self.darwinConfigurations.${host}.pkgs;
    };
}
