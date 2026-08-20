#!/bin/bash
# Panel de sesiones y agentes de Claude Code, para un pane lateral de tmux.
#
#   ⏎      sesión con pane -> salta a él;  agente -> abre su detalle
#   ␣      abre el detalle en un flotante encima
#   ^r     recarga
#   esc    cierra el flotante (y también el panel)
#
# El flotante usa fzf como visor en vez de `less` porque fzf sale con esc de
# serie; en less, esc es prefijo de secuencias y no se puede atar a "salir".

D="$HOME/.config/tmux/scripts"
PROYECTO="${1:-$PWD}"
PANE_ORIGEN="${2:-}"

# {1} vacío = fila de cabecera: no hay nada que abrir
VER='[ -n {1} ] && tmux display-popup -w 84% -h 80% -b rounded \
  -s "fg=#cdd6f4,bg=#181825" -S "fg=#585b70" -T " {3} " \
  -E "python3 '"$D"'/claude-detalle.py {1} --seguir | fzf --ansi --no-sort --tac \
      --layout=reverse-list --info=hidden --no-scrollbar --prompt=\"  \" \
      --color=\"fg:#cdd6f4,bg:-1,hl:#f38ba8,prompt:#cba6f7,pointer:#cba6f7\" \
      --header=\"esc para cerrar\" --header-first"'

python3 "$D/claude-bg.py" --cwd "$PROYECTO" --lista --pane "$PANE_ORIGEN" | fzf \
  --ansi --delimiter='\t' --with-nth=3 \
  --layout=reverse --info=hidden --border=none --no-scrollbar \
  --prompt='  ' --pointer='▸' \
  --color='fg:#cdd6f4,fg+:#cdd6f4,bg:-1,bg+:#313244,hl:#f38ba8,hl+:#f38ba8,pointer:#cba6f7,prompt:#cba6f7,header:#6c7086' \
  --header="$(basename "$PROYECTO")   ⏎ ir · ␣ detalle · ^r recargar" \
  --header-first \
  --bind="ctrl-r:reload(python3 $D/claude-bg.py --cwd '$PROYECTO' --lista --pane '$PANE_ORIGEN')" \
  --bind="space:execute($VER)" \
  --bind="enter:execute(
      destino={2};
      if [ -n \"\$destino\" ]; then
        tmux switch-client -t \"\${destino%%:*}\" 2>/dev/null
        tmux select-window -t \"\${destino%.*}\" 2>/dev/null
        tmux select-pane  -t \"\$destino\"      2>/dev/null
      else
        $VER
      fi)"
