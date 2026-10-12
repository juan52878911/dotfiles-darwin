#!/bin/sh
# Límites de uso de Claude Code (5 h y 7 días) para la barra de tmux, desde el collector de Nod
# (github.com/juan52878911/nod). Sin datos no imprime nada: así la barra no deja un separador suelto.
limits=$(nod-collector limits --format tmux 2>/dev/null) || exit 0
[ -n "$limits" ] && printf '#[fg=#585b70]  ▐  %s' "$limits"
exit 0
