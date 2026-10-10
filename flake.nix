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
      pkgs = nixpkgs.legacyPackages.${system};

      sistema = nix-darwin.lib.darwinSystem {
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
    in {
      # Con el nombre real del Mac (LocalHostName), `darwin-rebuild switch --flake
      # ~/dotfiles` funciona sin `#…`; el nombre antiguo se mantiene por costumbre.
      darwinConfigurations = {
        "MacBook-Pro-de-Juan-2" = sistema;
        "MacBook-Pro-de-Juan" = sistema;
      };

      # `nix run ~/dotfiles#switch`: aplica la configuración desde la copia local
      # (con su submódulo privado). Ruta absoluta de darwin-rebuild: el PATH de
      # sudo no incluye /run/current-system/sw/bin.
      apps.${system}.switch = {
        type = "app";
        program = toString (pkgs.writeShellScript "switch" ''
          exec sudo /run/current-system/sw/bin/darwin-rebuild switch \
            --flake "''${DOTFILES:-$HOME/dotfiles}" "$@"
        '');
      };

      formatter.${system} = pkgs.nixfmt-rfc-style;

      # `nix flake check`: que el sistema completo evalúa y compila.
      checks.${system}.sistema = sistema.system;
    };
}
