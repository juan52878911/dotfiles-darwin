{
  description = "Entorno Node reproducible";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  outputs = { nixpkgs, ... }:
    let
      # Mac (Apple Silicon e Intel) y Linux (homelab): el mismo flake en todos.
      sistemas = [ "aarch64-darwin" "x86_64-darwin" "aarch64-linux" "x86_64-linux" ];
      porSistema = f: nixpkgs.lib.genAttrs sistemas (s: f nixpkgs.legacyPackages.${s});
    in {
      devShells = porSistema (pkgs: {
        default = pkgs.mkShell {
          # Cambia la versión aquí: nodejs_22, nodejs_24...
          # OJO: nodejs_20 ya NO está en nixpkgs (EOL). Para Node 20 sigue usando nvm.
          packages = with pkgs; [ nodejs_24 pnpm typescript-language-server ];
          shellHook = ''echo "node $(node --version)"'';
        };
      });
    };
}
