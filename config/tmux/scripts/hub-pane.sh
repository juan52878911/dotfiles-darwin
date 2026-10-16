#!/bin/bash
# La épica del IA hub de Trycore con la que trabaja el Claude Code de un pane: `hub EP-001`. Solo si la
# sesión está conectada de verdad; si no, no imprime nada. Lo usa float-title.sh.
#
# Uso: hub-pane.sh <pane_id>
#
# Conectada quiere decir las dos cosas:
#  - el Claude manda sus eventos de Nod al hub (NOD_SINKS con su ruta /nod, como trycore-demo-hub/sesion-hub.sh),
#    que es lo que el hub analiza por épica;
#  - el proyecto está registrado en el hub (.claude/state/runtime.credentials) y su proyección
#    (runtime-projection.json, la que escribe el arnés al arrancar) tiene una épica activa.
# Color de la épica: verde al día, amarillo si la proyección está vieja o el daemon no llega al hub, rojo si
# perdió el lease. Todo sale de ficheros locales: sin red.
# float-title.sh ya lo buscó y lo pasa en CLAUDE_PANE; si no, se busca aquí.
read -r pid _ cwd <<<"${CLAUDE_PANE-$(~/.config/tmux/scripts/claude-pane.sh "$1")}"
[ -n "$pid" ] || exit 0
ps eww -o command= -p "$pid" | tr ' ' '\n' | grep -q '^NOD_SINKS=.*/nod' || exit 0

root=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null) || exit 0
state="$root/.claude/state"
# En un worktree sin registro propio, el arnés usa el del clon principal.
if [ ! -f "$state/runtime.credentials" ]; then
  common=$(git -C "$cwd" rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || exit 0
  state="$(dirname "$common")/.claude/state"
fi
[ -f "$state/runtime.credentials" ] && [ -f "$state/runtime-projection.json" ] || exit 0

# jq en vez de Python: arranca en ~5 ms frente a ~40.
jq -rn --argjson now "$(date +%s)" \
  --slurpfile p "$state/runtime-projection.json" \
  --argjson h "$(cat "$state/heartbeat-status.json" 2>/dev/null || echo '{}')" '
  ($p[0].active_slice.epic_code // empty) as $epic
  | ((try ($now - ($p[0].fetched_at | fromdateiso8601)) catch 0) // 0) as $edad
  | (if $h.lease_lost then "#f38ba8"
     elif ($h.context_stale or $edad > 900) then "#f9e2af"
     else "#a6e3a1" end) as $color
  | "#[fg=#6c7086]hub#[default] #[fg=\($color)]\($epic)#[default]"' 2>/dev/null
