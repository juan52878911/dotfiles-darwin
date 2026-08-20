#!/bin/bash
# Panel de sesiones y agentes de Claude Code, para un pane lateral de tmux.
#
#   enter   sesión con pane -> salta a él;  agente -> abre su detalle
#   space   abre el detalle en un flotante, sin moverse de sitio
#   ctrl-r  recarga la lista
#
# Sin vista previa fija a propósito: la lista sola se lee mejor, y el detalle
# aparece en un popup encima cuando lo pides.

D="$HOME/.config/tmux/scripts"
PROYECTO="${1:-$PWD}"
PANE_ORIGEN="${2:-}"

# Popup de detalle, con los mismos colores que el resto de la interfaz
DETALLE="tmux display-popup -w 82% -h 78% -b rounded \
  -s 'fg=#cdd6f4,bg=#181825' -S 'fg=#585b70' \
  -T ' detalle ' -E \"python3 $D/claude-detalle.py {1} --seguir | less -R +F\""

python3 "$D/claude-bg.py" --cwd "$PROYECTO" --lista --pane "$PANE_ORIGEN" | fzf \
  --ansi --delimiter='\t' --with-nth=3 \
  --layout=reverse --info=hidden --border=none --no-scrollbar \
  --prompt='  ' --pointer="▸" --color='fg:#cdd6f4,fg+:#cdd6f4,bg:-1,bg+:#313244,hl:#f38ba8,hl+:#f38ba8,pointer:#cba6f7,prompt:#cba6f7,header:#6c7086,border:#585b70' \
  --header="$(basename "$PROYECTO")   ⏎ ir · ␣ detalle · ^r recargar" \
  --header-first \
  --bind="ctrl-r:reload(python3 $D/claude-bg.py --cwd '$PROYECTO' --lista --pane '$PANE_ORIGEN')" \
  --bind="space:execute($DETALLE)" \
  --bind='enter:execute(
      destino={2};
      if [ -n "$destino" ]; then
        tmux switch-client -t "${destino%%:*}" 2>/dev/null
        tmux select-window -t "${destino%.*}" 2>/dev/null
        tmux select-pane  -t "$destino"      2>/dev/null
      else
        tmux display-popup -w 82% -h 78% -b rounded \
          -s "fg=#cdd6f4,bg=#181825" -S "fg=#585b70" -T " detalle " \
          -E "python3 '"$D"'/claude-detalle.py {1} --seguir | less -R +F"
      fi)'
