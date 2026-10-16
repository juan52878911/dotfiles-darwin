#!/bin/bash
# Contexto, límite de 5 h y su renovación del Claude Code que corre en un pane, desde Nod:
# `ctx 63% · 5h 18% ↻2h10 · 7d 24%`. Lo usa el título del popup de las flotantes (float-title.sh). Sin Claude
# en el pane, o sin datos de Nod para su sesión, no imprime nada.
#
# Uso: nod-pane.sh <pane_id>   (p. ej. #{pane_id} = %18)
# float-title.sh ya lo buscó y lo pasa en CLAUDE_PANE; si no, se busca aquí.
read -r _ sid _ <<<"${CLAUDE_PANE-$(~/.config/tmux/scripts/claude-pane.sh "$1")}"
[ -n "$sid" ] || exit 0
# @nod_collector (opción global de tmux) cambia el binario, p. ej. un build local de nod sin instalar.
bin=$(tmux show -gqv @nod_collector 2>/dev/null)
"${bin:-nod-collector}" limits --format tmux --session "$sid" 2>/dev/null
exit 0
