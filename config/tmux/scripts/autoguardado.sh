#!/bin/bash
# Autoguardado de tmux-continuum sin pasar por la barra de estado.
#
# continuum mete `#(continuum_save.sh)` en status-right: se ejecuta en cada refresco de la barra (cada 15 s)
# solo para mirar si ya pasaron los 15 minutos, y eso son ~50 ms de bash y varias llamadas a tmux cada vez.
# Aquí se quita de la barra y un único proceso duerme el intervalo de continuum y entonces llama al mismo
# script, que sigue decidiendo si toca guardar y guardando igual que antes. La restauración al arrancar no
# cambia. Lo lanza tmux.conf después de TPM; un vigilante por servidor.
quitar() {
  local opcion=$1 v
  v=$(tmux show -gv "$opcion" 2>/dev/null)
  [[ "$v" == *continuum_save.sh* ]] || return 0
  # El trozo exacto que añade continuum: #(<ruta>/continuum_save.sh)
  v=$(printf '%s' "$v" | sed 's|#([^)]*continuum_save\.sh)||g')
  tmux set -g "$opcion" "$v"
}
quitar status-right
quitar status-left

script="$HOME/.tmux/plugins/tmux-continuum/scripts/continuum_save.sh"
[ -x "$script" ] || exit 0

viejo=$(tmux show -gqv @autoguardado_pid)
[ -n "$viejo" ] && kill -0 "$viejo" 2>/dev/null && exit 0
tmux set -g @autoguardado_pid $$

while tmux has-session 2>/dev/null; do
  minutos=$(tmux show -gqv @continuum-save-interval)
  [ "${minutos:-15}" -gt 0 ] 2>/dev/null || minutos=15
  sleep $((minutos * 60))
  "$script"
done
