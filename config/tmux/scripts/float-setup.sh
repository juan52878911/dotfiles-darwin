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

MARCA="#{?#{m:f-*,#{session_name}}"

envolver() {
  local opcion="$1" simple="$2"
  local actual
  actual=$(tmux show -gwv "$opcion" 2>/dev/null)
  # Ya envuelto o vacío -> nada que hacer
  [[ -z "$actual" || "$actual" == "$MARCA"* ]] && return 0
  tmux setw -g "$opcion" "${MARCA},${simple},${actual}}"
}

# En el flotante: gris el número inactivo, malva y negrita el actual.
# Con una sola ventana no se muestra nada: saber que estás en la 1 de 1 no aporta.
envolver window-status-format         '#{?#{>:#{session_windows},1},#[fg=#585b70] #I ,}'
envolver window-status-current-format '#{?#{>:#{session_windows},1},#[fg=#cba6f7#,bold] #I ,}'
