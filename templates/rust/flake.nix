{
  description = "Entorno Rust reproducible";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  outputs = { nixpkgs, ... }:
    let
      sistema = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${sistema};
    in {
      devShells.${sistema}.default = pkgs.mkShell {
        packages = [ pkgs.cargo pkgs.rustc pkgs.rust-analyzer pkgs.clippy ];
        shellHook = ''echo "rust $(rustc --version | cut -d" " -f2)"'';
      };
    };
}
