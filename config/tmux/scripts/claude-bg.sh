#!/bin/bash
# Panel de procesos en segundo plano de Claude Code, para un pane de tmux.
#
# Junta las dos fuentes que Claude Code deja en disco:
#   ~/.claude/jobs/<id>/state.json          sesiones de agente en background (/bg)
#   $TMPDIR/claude-<uid>/<proy>/<ses>/tasks/*.output   salida de bash en background
#
# Solo lee ficheros; no lanza procesos pesados ni consulta la API.
exec python3 "$HOME/.config/tmux/scripts/claude-bg.py" "$@"
