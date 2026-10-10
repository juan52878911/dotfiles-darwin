{
  description = "Entorno Rust reproducible";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  outputs = { nixpkgs, ... }:
    let
      # Mac (Apple Silicon e Intel) y Linux (homelab): el mismo flake en todos.
      sistemas = [ "aarch64-darwin" "x86_64-darwin" "aarch64-linux" "x86_64-linux" ];
      porSistema = f: nixpkgs.lib.genAttrs sistemas (s: f nixpkgs.legacyPackages.${s});
    in {
      devShells = porSistema (pkgs: {
        default = pkgs.mkShell {
          packages = with pkgs; [ cargo rustc rust-analyzer clippy rustfmt ];
          shellHook = ''echo "rust $(rustc --version | cut -d" " -f2)"'';
        };
      });
    };
}
