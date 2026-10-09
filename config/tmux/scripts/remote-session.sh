#!/bin/bash
# Sesiones remotas: una sesión de tmux local cuyas ventanas y panes son SSH a un
# equipo. El mapa nombre=host sale de la opción global @remote_sessions
# (p. ej. "Trabajo=pc-trabajo"; el host es un alias de ~/.ssh/config).
#
#   remote-session.sh open  <sesión>   crea la sesión si falta y salta a ella
#   remote-session.sh apply <sesión>   marca una sesión ya creada (hook session-created)
#
# "Marcar" = fijar @ssh_host y default-command en la sesión. Con eso:
#   - prefix+c y cualquier split sin comando abren `ssh <host>`
#   - tmux-ssh-split (prefix+v / prefix+d) abre el pane en la misma carpeta remota
#   - Alt+g (float-open.sh) abre la flotante f-<sesión> también por SSH
# La flotante f-<sesión> hereda el host de su sesión principal.

accion="$1"
sesion="$2"
[[ -z "$accion" || -z "$sesion" ]] && exit 0

host_de() {
  local base="${1#f-}" par
  for par in $(tmux show -gqv @remote_sessions); do
    [[ "${par%%=*}" == "$base" ]] && { echo "${par#*=}"; return; }
  done
}

host=$(host_de "$sesion")
[[ -z "$host" ]] && exit 0

marcar() {
  tmux set -t "=$1:" @ssh_host "$host"
  tmux set -t "=$1:" default-command "ssh $host"
}

case "$accion" in
  apply)
    marcar "$sesion"
    ;;
  open)
    if ! tmux has-session -t "=$sesion" 2>/dev/null; then
      tmux new-session -d -s "$sesion" "ssh $host"
      marcar "$sesion"
    fi
    tmux switch-client -t "=$sesion"
    ;;
esac
