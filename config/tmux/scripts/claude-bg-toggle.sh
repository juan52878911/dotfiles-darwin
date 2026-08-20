#!/bin/bash
# Abre o cierra el panel lateral de procesos en segundo plano.
#
# En un script y no en el .tmux.conf porque encadenar comandos con
# continuaciones de línea dentro de un bloque `{ }` de tmux es frágil y falla
# en silencio (ya pasó con el -T del popup).

ANCHO=${1:-38}
id=$(tmux show -gv @bg_panel_id 2>/dev/null)

# Si hay un panel registrado y sigue vivo, lo cerramos
if [[ -n "$id" ]] && tmux list-panes -a -F '#{pane_id}' 2>/dev/null | grep -qx "$id"; then
  tmux kill-pane -t "$id" 2>/dev/null
  tmux set -gu @bg_panel_id 2>/dev/null
  exit 0
fi

nuevo=$(tmux split-window -h -l "$ANCHO" -P -F '#{pane_id}' \
  "while :; do clear; $HOME/.config/tmux/scripts/claude-bg.sh; sleep 5; done" 2>/dev/null)

if [[ -n "$nuevo" ]]; then
  tmux set -g @bg_panel_id "$nuevo"
  tmux select-pane -L          # devolver el foco a donde estabas
fi
