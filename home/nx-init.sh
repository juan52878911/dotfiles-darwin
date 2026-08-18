#!/bin/bash
# Arranca un entorno reproducible de Nix en la carpeta actual.
#   uso: nx-init node|python|rust
#
# Hace tres cosas que hay que hacer juntas o no funciona:
#   1. copia flake.nix y .envrc de la plantilla
#   2. si estamos dentro de un repo git, marca flake.nix con `git add -N`.
#      Nix NO ve archivos sin rastrear dentro de un repo: sin esto el flake
#      falla con "not tracked by Git" y direnv no carga nada.
#      -N (intent-to-add) lo hace visible sin meter contenido al índice.
#   3. autoriza el .envrc

tipo="$1"
plantilla="$HOME/dotfiles/templates/$tipo"

if [[ -z "$tipo" || ! -d "$plantilla" ]]; then
  echo "uso: nx-init node|python|rust" >&2
  exit 1
fi

cp -n "$plantilla/flake.nix" . 2>/dev/null
cp -n "$plantilla/.envrc" .   2>/dev/null

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git add -N flake.nix 2>/dev/null
  echo "flake.nix marcado para git (necesario para que Nix lo vea)"
fi

# .direnv/ es cache local; .envrc suele ir ignorado por proyecto
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  grep -q "^.direnv" .gitignore 2>/dev/null || printf '.direnv/\n' >> .gitignore
fi

direnv allow . && echo "listo — entra de nuevo en la carpeta o ejecuta: direnv reload"
