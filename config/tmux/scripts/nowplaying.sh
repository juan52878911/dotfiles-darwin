#!/bin/bash
# Módulo de música para la barra de tmux.
#
# Sustituye a los 3 scripts del plugin tmux-spotify-status (icono, texto y estado
# por separado, cada uno con su osascript). Aquí es UNA sola llamada a
# nowplaying-cli, que lee el "Now Playing" del sistema — por eso funciona con
# Tidal, que NO es scriptable con AppleScript (no trae .sdef), y también con
# Spotify, Apple Music o cualquier app que publique su reproducción.
#
# Si no suena nada no imprime nada, así el módulo desaparece de la barra en vez
# de dejar una píldora de color vacía.

command -v nowplaying-cli >/dev/null 2>&1 || exit 0

MAX_LEN=28           # caracteres visibles antes de recortar
SEP_COLOR="#585b70"  # gris del separador, el mismo de hora y fecha
TEXT_COLOR="#6c7086"  # gris tenue: se lee al buscarla, no empuja la hora

# Una sola llamada; python devuelve 4 líneas en orden fijo.
# Nota: nada de `mapfile` — macOS trae bash 3.2 y no lo tiene.
datos=$(
  nowplaying-cli get --json title artist playbackRate clientBundleIdentifier 2>/dev/null |
  python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    print("\n\n\n"); sys.exit(0)
def s(k):
    v = d.get(k)
    return "" if v in (None, "null") else " ".join(str(v).split())
for k in ("title", "artist", "playbackRate", "clientBundleIdentifier"):
    print(s(k))
' 2>/dev/null
)

{
  IFS= read -r title
  IFS= read -r artist
  IFS= read -r rate
  IFS= read -r bundle
} <<EOF
$datos
EOF

# Sin título = nada sonando -> módulo invisible
[[ -z "$title" ]] && exit 0

# Icono y color según la app de origen (identidad de la app)
case "$bundle" in
  com.tidal.desktop)  icon=""; color="#74c7ec" ;;  # Tidal: onda, azul zafiro
  com.spotify.client) icon="󰓇"; color="#a6e3a1" ;;  # Spotify: logo, verde
  com.apple.Music)    icon=""; color="#f38ba8" ;;  # Apple Music: manzana, rojo
  *)                  icon="󰝚"; color="#cba6f7" ;;  # cualquier otra: nota musical
esac

# Indicador de estado, aparte del icono de la app: así se distingue de un vistazo
# si está sonando o en pausa sin perder de vista de qué app viene.
if [[ "$rate" == "0" || "$rate" == "0.0" ]]; then
  estado="󰏤"              # pausa
  color="#6c7086"         # app apagada
  ESTADO_COLOR="#6c7086"
  TEXT_COLOR="#6c7086"
else
  estado="󰐊"              # reproduciendo
  ESTADO_COLOR="$color"   # el triángulo toma el color de la app
fi

# "Artista — Título", recortado con puntos suspensivos si no cabe
if [[ -n "$artist" ]]; then texto="$artist — $title"; else texto="$title"; fi
if (( ${#texto} > MAX_LEN )); then texto="${texto:0:MAX_LEN}…"; fi

printf '#[fg=%s]  ▐  #[fg=%s]%s #[fg=%s]%s  #[fg=%s]%s' \
  "$SEP_COLOR" "$color" "$icon" "$ESTADO_COLOR" "$estado" "$TEXT_COLOR" "$texto"
