#!/bin/bash
# Lleva el foco a la sesión indicada.
#
#   claude-ir.sh <destino>   destino = sesion:ventana.pane, o vacío
#
# La clave está en dónde estás AHORA:
#
#   · Si ya estás dentro de un flotante (sesión f-*), abrir otro popup lo apilaría
#     encima del que ya ves. Lo correcto es `switch-client`: el popup pasa a
#     mostrar la sesión elegida, que es lo que se busca.
#   · Si estás en un pane normal y el destino es un flotante, sí hay que abrir su
#     popup: un `switch-client` a una f-* no muestra nada nuevo, porque esas
#     sesiones están pensadas para servirse en popup.
#   · Sin destino, la sesión corre en Claude Desktop y no hay a dónde ir.

destino="$1"

if [[ -z "$destino" ]]; then
  tmux display-message -d 2500 " esa sesión corre en Claude Desktop, no en tmux"
  exit 0
fi

sesion="${destino%%:*}"
aqui=$(tmux display-message -p '#{session_name}' 2>/dev/null)

ir_directo() {
  tmux switch-client -t "$sesion"       2>/dev/null
  tmux select-window -t "${destino%.*}" 2>/dev/null
  tmux select-pane   -t "$destino"      2>/dev/null
}

case "$aqui" in
  f-*)
    # Ya estamos en un flotante: cambiar lo que muestra, no apilar otro
    ir_directo
    ;;
  *)
    case "$sesion" in
      f-*)
        dir=$(tmux display-message -p '#{pane_current_path}' 2>/dev/null)
        tmux display-popup -w 80% -h 85% -d "$dir" \
          -b rounded -s "fg=#cdd6f4,bg=#181825" -S "fg=#585b70" \
          -T " ${sesion#f-} " -E "tmux attach -t '$sesion'"
        ;;
      *) ir_directo ;;
    esac
    ;;
esac
