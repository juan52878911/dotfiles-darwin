#!/bin/bash
# El Claude Code que corre en un pane de tmux: imprime `<pid> <sessionId> <cwd>` (nada si no hay ninguno).
# Lo usan nod-pane.sh, hub-pane.sh y float-title.sh.
#
# Uso: claude-pane.sh <pane_id>   (p. ej. #{pane_id} = %18)
#
# Claude Code deja <config>/sessions/<pid>.json con su sessionId, su cwd y el pane de tmux en el que corre
# ("tmux":"f-x:@18.%18"). El proceso del pane no sirve: con claude-auto-retry es `node`. <config> es ~/.claude
# o el CLAUDE_CONFIG_DIR de cada perfil de ws. Un solo grep sobre todos los ficheros: así cuesta lo mismo
# con 3 sesiones abiertas que con 30.
pane=$1
[ -n "$pane" ] || exit 0

best=
newest=0
while IFS= read -r f; do
  # Un fichero de un Claude que murió sin limpiarlo no cuenta.
  pid=${f##*/}; pid=${pid%.json}
  kill -0 "$pid" 2>/dev/null || continue
  json=$(<"$f")
  upd=${json#*\"updatedAt\":}; upd=${upd%%[!0-9]*}
  if [ "${upd:-0}" -gt "$newest" ]; then
    newest=${upd:-0}
    best=$json
  fi
done < <(grep -lF ".${pane}\"" "$HOME"/.claude/sessions/*.json "$HOME"/.local/state/ws/claude/*/sessions/*.json 2>/dev/null)
[ -n "$best" ] || exit 0

pid=${best#*\"pid\":}; pid=${pid%%[!0-9]*}
sid=${best#*\"sessionId\":\"}; sid=${sid%%\"*}
cwd=${best#*\"cwd\":\"}; cwd=${cwd%%\"*}
printf '%s %s %s\n' "$pid" "$sid" "$cwd"
