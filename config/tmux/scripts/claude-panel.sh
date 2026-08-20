#!/bin/bash
# Panel de sesiones y agentes de Claude Code, para un pane lateral de tmux.
# Los atajos no se anuncian: se ven pulsando h.

D="$HOME/.config/tmux/scripts"
PROYECTO="${1:-$PWD}"
PANE_ORIGEN="${2:-}"

COLORES='fg:#cdd6f4,fg+:#cdd6f4,bg:-1,bg+:#313244,hl:#f38ba8,hl+:#f38ba8,pointer:#cba6f7,prompt:#cba6f7,header:#6c7086,border:#585b70'

# Visor del detalle.
# OJO: nada de `--seguir` aquí. fzf con --tac espera el fin de la entrada para
# poder invertirla, y un tail infinito no termina nunca: la ventana salía vacía
# y no cerraba. Se muestra una foto, y ^r la refresca.
# Visor del detalle: script propio, no fzf ni less.
# Al imprimir en un terminal normal el desplazamiento es natural, así que la vista
# queda SIEMPRE en lo último y ocupa todo el alto. Sale con esc o q.
VER='[ -n {1} ] && tmux display-popup -w 88% -h 92% -b rounded \
  -s "fg=#cdd6f4,bg=#181825" -S "fg=#585b70" -T " {3} " \
  -E "python3 '"$D"'/claude-detalle.py {1} --visor"'

AYUDA='tmux display-popup -w 40 -h 12 -b rounded \
  -s "fg=#cdd6f4,bg=#181825" -S "fg=#585b70" -T " atajos " -E "printf \"
  \033[38;2;203;166;247m⏎\033[0m   ir a la sesión / ver detalle
  \033[38;2;203;166;247m␣\033[0m   detalle en flotante
  \033[38;2;203;166;247m^r\033[0m  recargar
  \033[38;2;203;166;247mesc\033[0m salir
  \033[38;2;203;166;247m/\033[0m   buscar
\n\"; read -rsn1"'

python3 "$D/claude-bg.py" --cwd "$PROYECTO" --lista --pane "$PANE_ORIGEN" | fzf \
  --ansi --delimiter='\t' --with-nth=3 --disabled \
  --layout=reverse --info=hidden --border=none --no-scrollbar \
  --prompt='' --pointer='▸' --color="$COLORES" \
  --header="$(basename "$PROYECTO")" --header-first \
  --bind="ctrl-r:reload(python3 $D/claude-bg.py --cwd '$PROYECTO' --lista --pane '$PANE_ORIGEN')" \
  --bind="h:execute($AYUDA)" \
  --bind='/:enable-search+change-prompt(  )' \
  --bind='j:down,k:up' \
  --bind="space:execute($VER)" \
  --bind="enter:execute(
      destino={2};
      if [ -n \"\$destino\" ]; then
        tmux switch-client -t \"\${destino%%:*}\" 2>/dev/null
        tmux select-window -t \"\${destino%.*}\" 2>/dev/null
        tmux select-pane  -t \"\$destino\"      2>/dev/null
      else
        tmux display-message -d 2500 \" esa sesión corre en Claude Desktop, no en tmux — abro su detalle\"
        $VER
      fi)"
