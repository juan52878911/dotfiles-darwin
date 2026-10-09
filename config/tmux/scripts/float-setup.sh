#!/bin/bash
# Envuelve los formatos de ventana para que las sesiones flotantes (f-*) muestren
# SOLO el número de ventana, y el resto conserve el formato de catppuccin.
#
# Por qué así y no con `setw -t <sesión>`: `window-status-format` es una opción
# de VENTANA, no de sesión — al fijarla por sesión solo afecta a la ventana
# activa en ese momento y las nuevas no la heredan. Envolviendo el formato
# GLOBAL en un condicional sobre el nombre de sesión funciona en todas, siempre.
#
# Se ejecuta después de TPM, cuando catppuccin ya definió sus formatos.
# Es idempotente: si ya está envuelto, no hace nada.
#
# OJO con las comas. tmux corta `#{?cond,a,b}` por la primera coma de nivel cero
# y NO trata `#[fg=x,bg=y]` como un nivel anidado: las comas de un estilo cuentan
# como separadores. Meter aquí el formato de catppuccin tal cual — que va lleno
# de `#[fg=#cdd6f4,bg=...]` — lo troceaba, y la pestaña acababa dibujándose como
# el texto literal `reverse]`. Por eso cada rama se guarda en una opción de
# usuario y el condicional solo lleva `#{E:@...}`, sin ninguna coma suelta.
# (En la rama flotante la coma del estilo sí va escapada como `#,`, porque ahí
# el condicional interior se evalúa dentro de la propia opción.)

MARCA="#{?#{m:f-*,#{session_name}}"

envolver() {
  local opcion="$1" simple="$2" clave="$3"
  local flotante="@float_${clave}_simple" normal="@float_${clave}_normal"
  local actual
  actual=$(tmux show -gwv "$opcion" 2>/dev/null)
  # Ya envuelto o vacío -> nada que hacer
  [[ -z "$actual" || "$actual" == "$MARCA"* ]] && return 0
  tmux set -g "$flotante" "$simple"
  tmux set -g "$normal" "$actual"
  tmux setw -g "$opcion" "${MARCA},#{E:${flotante}},#{E:${normal}}}"
}

# En el flotante: gris el número inactivo, malva y negrita el actual.
# Con una sola ventana no se muestra nada: saber que estás en la 1 de 1 no aporta.
envolver window-status-format \
  '#{?#{>:#{session_windows},1},#[fg=#585b70] #I ,}' wsf
envolver window-status-current-format \
  '#{?#{>:#{session_windows},1},#[fg=#cba6f7#,bold] #I ,}' wscf
