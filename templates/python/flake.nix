{
  description = "Entorno Python reproducible";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  outputs = { nixpkgs, ... }:
    let
      # Mac (Apple Silicon e Intel) y Linux (homelab): el mismo flake en todos.
      sistemas = [ "aarch64-darwin" "x86_64-darwin" "aarch64-linux" "x86_64-linux" ];
      porSistema = f: nixpkgs.lib.genAttrs sistemas (s: f nixpkgs.legacyPackages.${s});
    in {
      devShells = porSistema (pkgs: {
        default = pkgs.mkShell {
          packages = with pkgs; [ python313 uv ruff ];
          shellHook = ''
            echo "python $(python3 --version | cut -d" " -f2)"
            [ -d .venv ] || python3 -m venv .venv
            source .venv/bin/activate
          '';
        };
      });
    };
}
