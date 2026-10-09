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
    # ws: organizaciones y espacios de trabajo (github.com/juan52878911/tmux-ws).
    # Actualizar: nix flake update tmux-ws
    tmux-ws = {
      url = "github:juan52878911/tmux-ws";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nix-darwin, home-manager, tmux-ws, ... }:
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
            # Si un archivo ya existe en $HOME, lo renombra en vez de fallar.
            # Sin esto, el primer switch aborta al encontrar .zshrc, .tmux.conf, etc.
            home-manager.backupFileExtension = "antes-de-nix";
            home-manager.extraSpecialArgs = { inherit usuario nixpkgs tmux-ws; };
            home-manager.users.${usuario} = import ./darwin/home.nix;
          }
        ];
      };

      # Atajo: `nix run .#switch`
      darwinPackages = self.darwinConfigurations.${host}.pkgs;
    };
}
