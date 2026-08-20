#!/bin/bash
# Lleva el foco a la sesión indicada.
#
#   claude-ir.sh <destino>   destino = sesion:ventana.pane, o vacío
#
# Distingue tres casos, que se comportan distinto:
#   · sesión flotante (f-*): NO se puede mostrar con switch-client — vive en un
#     popup. Hay que reabrir el popup, igual que hace Alt+g.
#   · sesión normal de tmux: switch-client + select-window + select-pane.
#   · sin destino (corre en Claude Desktop): no hay nada a lo que ir.

destino="$1"

if [[ -z "$destino" ]]; then
  tmux display-message -d 2500 " esa sesión corre en Claude Desktop, no en tmux"
  exit 0
fi

sesion="${destino%%:*}"

case "$sesion" in
  f-*)
    # Reabrir el flotante. Se detacha primero cualquier cliente pegado a ella,
    # porque una sesión sirviéndose en dos sitios a la vez se ve rara.
    dir=$(tmux display-message -p '#{pane_current_path}' 2>/dev/null)
    tmux display-popup -w 80% -h 85% -d "$dir" \
      -b rounded -s "fg=#cdd6f4,bg=#181825" -S "fg=#585b70" \
      -T " ${sesion#f-} " \
      -E "tmux attach -t '$sesion'"
    ;;
  *)
    tmux switch-client -t "$sesion"           2>/dev/null
    tmux select-window -t "${destino%.*}"     2>/dev/null
    tmux select-pane   -t "$destino"          2>/dev/null
    ;;
esac
