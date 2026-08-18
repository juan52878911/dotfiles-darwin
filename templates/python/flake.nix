{
  description = "Entorno Python reproducible";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  outputs = { nixpkgs, ... }:
    let
      sistema = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${sistema};
    in {
      devShells.${sistema}.default = pkgs.mkShell {
        packages = [ pkgs.python313 pkgs.uv pkgs.ruff ];
        shellHook = ''
          echo "python $(python3 --version | cut -d" " -f2)"
          [ -d .venv ] || python3 -m venv .venv
          source .venv/bin/activate
        '';
      };
    };
}
