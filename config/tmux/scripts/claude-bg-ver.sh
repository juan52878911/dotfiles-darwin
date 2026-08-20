#!/bin/bash
# Selector de procesos en segundo plano: elige uno con fzf y mira su contenido.
# Pensado para lanzarse en un popup de tmux.

D="$HOME/.config/tmux/scripts"

# Mismo proyecto que el pane desde el que se abre; --todos para ver la máquina entera
proyecto=$(tmux display-message -p '#{pane_current_path}' 2>/dev/null || echo "$PWD")
ambito=(--cwd "$proyecto")
[[ "$1" == "--todos" ]] && ambito=(--todos)

sel=$(python3 "$D/claude-bg.py" "${ambito[@]}" --pick 2>/dev/null | fzf \
  --delimiter='\t' --with-nth=2 \
  --prompt='  proceso  ' --pointer='▶' --height=100% \
  --preview="tail -n 400 {1} 2>/dev/null || echo 'sin salida todavía'" \
  --preview-window=right:65%:wrap \
  --header="proyecto: $(basename \"$proyecto\") · enter: abrir · ctrl-c: salir") || exit 0

ruta=$(printf '%s' "$sel" | cut -f1)
[[ -z "$ruta" || ! -e "$ruta" ]] && exit 0

# Los state.json se ven mejor formateados; la salida cruda va tal cual
case "$ruta" in
  *.json) python3 -m json.tool "$ruta" 2>/dev/null | less -R || less -R "$ruta" ;;
  *)      less -R +G "$ruta" ;;
esac
