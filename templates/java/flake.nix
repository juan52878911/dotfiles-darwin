{
  description = "Entorno Java reproducible";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  outputs = { nixpkgs, ... }:
    let
      # Mac (Apple Silicon e Intel) y Linux (homelab): el mismo flake en todos.
      sistemas = [ "aarch64-darwin" "x86_64-darwin" "aarch64-linux" "x86_64-linux" ];
      porSistema = f: nixpkgs.lib.genAttrs sistemas (s: f nixpkgs.legacyPackages.${s});
    in {
      devShells = porSistema (pkgs: {
        default = pkgs.mkShell {
          # Java 21 + Maven. Para Gradle: añade `gradle`.
          packages = with pkgs; [ jdk21 maven jdt-language-server ];
          shellHook = ''
            export JAVA_HOME=${pkgs.jdk21}
            java -version 2>&1 | head -1
          '';
        };
      });
    };
}
