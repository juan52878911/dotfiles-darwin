#!/bin/bash
# Título del popup de la flotante f-<sesión>, en el propio borde para no gastar filas dentro:
#
#   ╭─ tc-oriuno  [1]  2 ───────────────────────────── ctx 63% · 5h 18% ↻2h10 · 7d 24% ─╮
#
# A la izquierda la sesión padre y, si hay más de una, las ventanas (la actual en malva). A la derecha, solo
# si en la ventana activa corre Claude Code: la épica del IA hub si la sesión está conectada (hub-pane.sh) y
# lo que Nod sabe de él (nod-pane.sh).
#
# tmux deja cambiar el título de un popup ya abierto repitiendo display-popup sobre su cliente. Pero si el
# popup está cerrado, ese mismo comando abriría uno nuevo; por eso solo se toca mientras la flotante tenga un
# cliente enganchado (el de dentro del popup). El cliente de fuera lo apunta float-open.sh en @float_client.
#
# Uso: float-title.sh <sesión>             refresca una vez (hooks al cambiar de ventana)
#      float-title.sh <sesión> --vigilar   refresca cada 10 s mientras la flotante siga abierta
#      float-title.sh <sesión> --titulo    solo imprime el título (float-open.sh, al abrir)
#      float-title.sh <cualquier sesión> --hook   si es una flotante f-*, repinta al momento con lo último
#                                                 que se supo de ese pane y luego recalcula (hooks de tmux)
if [ "$2" = --hook ]; then
  [[ "$1" == f-* ]] || exit 0
  set -- "${1#f-}" --rapido
fi
SESS=$1
F="f-$SESS"
[ -n "$SESS" ] || exit 0

abierta() { [ -n "$(tmux list-clients -t "=$F" -F x 2>/dev/null)" ]; }

# Pestañas y pane activo en una sola llamada a tmux. Deja PANE con el pane activo y imprime la parte izquierda.
izquierda() {
  local t=" $SESS " activa idx pane lista="" n=0
  while read -r activa idx pane; do
    n=$((n + 1))
    # La actual entre corchetes y en malva; el resto, en gris.
    if [ "$activa" = 1 ]; then
      lista+=" #[fg=#cba6f7,bold][$idx]#[default]"
      PANE=$pane
    else
      lista+=" #[fg=#6c7086] $idx #[default]"
    fi
  done < <(tmux list-windows -t "=$F:" -F '#{window_active} #{window_index} #{pane_id}' 2>/dev/null)
  # Saber que estás en la 1 de 1 no aporta.
  [ "$n" -gt 1 ] && t+="$lista "
  IZQ=$t
}

# La derecha: la épica del hub y lo que Nod sabe de la sesión, separados por un punto medio. Es lo caro
# (~40 ms): el Claude del pane se busca una vez para los dos scripts, y el resultado se guarda en el pane
# (@float_derecha) para repintar al instante al cambiar de pestaña.
derecha() {
  local d
  CLAUDE_PANE=$(~/.config/tmux/scripts/claude-pane.sh "$PANE")
  export CLAUDE_PANE
  if [ -n "$CLAUDE_PANE" ]; then
    d=$( { ~/.config/tmux/scripts/hub-pane.sh "$PANE"; ~/.config/tmux/scripts/nod-pane.sh "$PANE"; } \
      | grep -v '^$' | paste -sd '|' - | sed 's/|/ · /g')
  fi
  tmux set -p -t "$PANE" @float_derecha "$d" 2>/dev/null
  DER=$d
}

titulo() {
  local t=$IZQ
  [ -n "$DER" ] && t+="#[align=right] $DER "
  printf '%s' "$t"
}

pintar() {
  local cliente
  cliente=$(tmux show -qv -t "=$F:" @float_client)
  [ -n "$cliente" ] || return 0
  abierta && tmux display-popup -c "$cliente" -T "$(titulo)"
}

if [ "$2" = --titulo ]; then
  izquierda; derecha; titulo
  exit 0
fi

if [ "$2" = --vigilar ]; then
  # Un solo vigilante por flotante: el de una apertura anterior se retira.
  viejo=$(tmux show -qv -t "=$F:" @float_title_pid)
  [ -n "$viejo" ] && kill "$viejo" 2>/dev/null
  tmux set -t "=$F:" @float_title_pid $$
  # El popup tarda un momento en enganchar su cliente.
  for _ in 1 2 3 4 5 6 7 8 9 10; do abierta && break; sleep 0.5; done
  # Solo se recalcula si Nod escribió algo desde la última vez (nuevo turno, nuevo usage) o si pasó un minuto
  # (la cuenta atrás ↻ va por minutos). Las comprobaciones son de bash, sin procesos: en reposo el vigilante
  # solo despierta para un `sleep` y un `tmux list-clients`. Cambiar de pestaña lo resuelven los hooks.
  eventos="${XDG_STATE_HOME:-$HOME/.local/state}/nod/events.jsonl"
  marca="${TMPDIR:-/tmp}/float-title-$UID-$SESS"
  ultimo=-60
  while abierta; do
    if [ "$eventos" -nt "$marca" ] || [ $((SECONDS - ultimo)) -ge 60 ]; then
      : >"$marca"
      ultimo=$SECONDS
      # Relanza el script en vez de llamar a sus funciones: si float-title.sh cambia con el popup abierto,
      # bash seguiría pintando la versión que leyó al arrancar.
      "$0" "$SESS"
    fi
    sleep 10
  done
  rm -f "$marca"
  exit 0
fi

izquierda
if [ "$2" = --rapido ]; then
  # Cambio de pestaña: primero lo que ya se sabía de ese pane, sin esperar a recalcular.
  DER=$(tmux show -pqv -t "$PANE" @float_derecha 2>/dev/null)
  pintar
fi
derecha
pintar
