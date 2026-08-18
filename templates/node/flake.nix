{
  description = "Entorno Node reproducible";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  outputs = { nixpkgs, ... }:
    let
      sistema = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${sistema};
    in {
      devShells.${sistema}.default = pkgs.mkShell {
        # Cambia la versión aquí: nodejs_22, nodejs_24...
        # OJO: nodejs_20 ya NO está en nixpkgs (EOL). Para Node 20 sigue usando nvm.
        packages = [ pkgs.nodejs_24 pkgs.pnpm pkgs.typescript-language-server ];
        shellHook = ''echo "node $(node --version)"'';
      };
    };
}
