#!/bin/bash
# Al cerrar una sesión, mata su flotante asociada para no dejar huérfanas.
#
# El flujo de Alt+g crea una sesión `f-<nombre>` por cada sesión normal. Si cierras
# la principal, la flotante se queda viva ocupando memoria y ensuciando el selector
# — y como el selector las filtra, ni siquiera las ves para matarlas a mano.
#
# Lo llama el hook `session-closed`, que expone #{hook_session_name}.

cerrada="$1"
[[ -z "$cerrada" ]] && exit 0

# Si la que se cerró YA era una flotante, no hay nada que hacer
case "$cerrada" in
  f-*) exit 0 ;;
esac

flotante="f-${cerrada}"

# has-session devuelve 0 si existe. Silenciamos porque el caso normal es que no exista.
if tmux has-session -t "=${flotante}" 2>/dev/null; then
  tmux kill-session -t "=${flotante}" 2>/dev/null
  # Rastro para poder depurar sin ver la sesión
  printf '%s  huérfana eliminada: %s (al cerrar %s)\n' \
    "$(date '+%Y-%m-%d %H:%M:%S')" "$flotante" "$cerrada" \
    >> "${TMPDIR:-/tmp}/tmux-huerfanas.log"
fi
