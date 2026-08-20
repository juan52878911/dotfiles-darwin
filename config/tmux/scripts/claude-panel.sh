#!/bin/bash
# Panel interactivo de sesiones y agentes de Claude Code.
#
# Se ejecuta dentro de un pane de tmux. Muestra las sesiones del proyecto actual,
# marca con ▶ las que corren en este mismo pane, y previsualiza en tiempo real lo
# que está haciendo cada una.
#
#   enter    saltar al pane de esa sesión
#   ctrl-r   recargar la lista
#   ctrl-o   abrir el detalle a pantalla completa
#   ratón    seleccionar (tmux tiene mouse on)

D="$HOME/.config/tmux/scripts"
PROYECTO="${1:-$PWD}"
# Pane desde el que se abrió el panel: sirve para marcar "estás aquí"
PANE_ORIGEN="${2:-}"

listar() {
  python3 "$D/claude-bg.py" --cwd "$PROYECTO" --lista --pane "$PANE_ORIGEN"
}
export -f listar 2>/dev/null

# --preview-window follow hace que la vista siga escribiendo sola: el script de
# detalle se queda leyendo el final del JSONL, así que es tiempo real de verdad.
listar | fzf \
  --ansi --delimiter='\t' --with-nth=3 \
  --layout=reverse --info=inline --border=none \
  --prompt='  ' --pointer='▸' --marker='✓' \
  --header="$(basename "$PROYECTO")  ·  enter: ir  ctrl-r: recargar  ctrl-o: detalle" \
  --header-first \
  --preview="python3 $D/claude-detalle.py {1} --seguir" \
  --preview-window='down,70%,follow,wrap,border-top' \
  --bind="ctrl-r:reload(python3 $D/claude-bg.py --cwd '$PROYECTO' --lista --pane '$PANE_ORIGEN')" \
  --bind="ctrl-o:execute(python3 $D/claude-detalle.py {1} --seguir)" \
  --bind='enter:become(
      destino={2};
      if [ -n "$destino" ]; then
        tmux switch-client -t "${destino%%:*}" 2>/dev/null
        tmux select-window -t "${destino%.*}" 2>/dev/null
        tmux select-pane -t "$destino" 2>/dev/null
      else
        tmux display-message "esa sesión no vive en tmux (corre en la app)"
      fi)'
