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

if [[ -n "$HOST" ]] && ! tmux has-session -t "=f-$SESS" 2>/dev/null; then
  tmux new-session -d -s "f-$SESS" -c "$DIR" "ssh $HOST"
fi

tmux display-popup -c "$CLIENTE" -w 80% -h 85% -d "$DIR" -b rounded \
  -s "fg=#cdd6f4,bg=#181825" -S "fg=#585b70" -T " $SESS " \
  -E "tmux new-session -A -s f-$SESS"
