#!/bin/bash
# Alt+g: abre la flotante f-<sesión> en un popup. Antes iba en línea en tmux.conf;
# ahora es script para soportar sesiones remotas (ver remote-session.sh).
#
# En una sesión remota la flotante tiene que nacer ya por SSH: el hook que fija
# default-command corre DESPUÉS de crear la sesión, así que el primer pane se
# abriría en local. Por eso aquí se crea en segundo plano con `ssh <host>` antes
# de mostrar el popup, que luego solo se engancha a ella (-A).

# Sin argumentos: la sesión y el cliente actuales (Alt+g). Con argumentos
# (`float-open.sh <sesión> <cliente>`) la reabre ws al volver a una sesión cuya
# flotante estaba abierta.
SESS=${1:-$(tmux display-message -p "#S")}
CLIENTE=${2:-$(tmux display-message -p "#{client_name}")}
DIR=$(tmux display-message -p -t "=$SESS:" "#{pane_current_path}")
HOST=$(tmux show -qv -t "=$SESS:" @ssh_host)

if ! tmux has-session -t "=f-$SESS" 2>/dev/null; then
  if [[ -n "$HOST" ]]; then
    tmux new-session -d -s "f-$SESS" -c "$DIR" "ssh $HOST"
  else
    tmux new-session -d -s "f-$SESS" -c "$DIR"
  fi
fi

# El borde del popup hace de barra (ventanas y Nod, ver float-title.sh): necesita saber qué cliente lo
# muestra, y se refresca solo mientras siga abierto.
tmux set -t "=f-$SESS:" @float_client "$CLIENTE"
TITULO=$(~/.config/tmux/scripts/float-title.sh "$SESS" --titulo)
nohup ~/.config/tmux/scripts/float-title.sh "$SESS" --vigilar >/dev/null 2>&1 &

tmux display-popup -c "$CLIENTE" -w 80% -h 85% -d "$DIR" -b rounded \
  -s "fg=#cdd6f4,bg=#181825" -S "fg=#585b70" -T "${TITULO:- $SESS }" \
  -E "tmux new-session -A -s f-$SESS"
