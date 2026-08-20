#!/bin/bash
# Abre o cierra el panel lateral de procesos en segundo plano.
#
# Va en un script y no en el .tmux.conf porque encadenar comandos con
# continuaciones de línea dentro de un bloque `{ }` de tmux falla en silencio.

ANCHO=${1:-46}   # solo la lista: no hace falta más
id=$(tmux show -gv @bg_panel_id 2>/dev/null)

# Si hay panel registrado y sigue vivo, cerrar
if [[ -n "$id" ]] && tmux list-panes -a -F '#{pane_id}' 2>/dev/null | grep -qx "$id"; then
  tmux kill-pane -t "$id" 2>/dev/null
  tmux set -gu @bg_panel_id 2>/dev/null
  exit 0
fi

# El proyecto es el directorio del pane desde el que se invoca, para que el panel
# muestre SOLO lo de este proyecto y no todo lo que haya en la máquina.
proyecto=$(tmux display-message -p '#{pane_current_path}' 2>/dev/null)
[[ -z "$proyecto" ]] && proyecto="$PWD"

# --watch redibuja en el sitio; el `while :; do clear; ...; done` de antes
# provocaba un parpadeo muy molesto en un pane fijo.
# El pane de origen se pasa para poder marcar con ▶ dónde estás ahora
origen=$(tmux display-message -p '#{session_name}:#{window_index}.#{pane_index}' 2>/dev/null)

nuevo=$(tmux split-window -h -l "$ANCHO" -P -F '#{pane_id}' \
  "exec $HOME/.config/tmux/scripts/claude-panel.sh '$proyecto' '$origen'" 2>/dev/null)

if [[ -n "$nuevo" ]]; then
  tmux set -g @bg_panel_id "$nuevo"
  tmux select-pane -L
fi
