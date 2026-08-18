# ~/.p10k.catppuccin.zsh — Catppuccin Mocha para powerlevel10k
#
# Se carga DESPUÉS de ~/.p10k.zsh y solo redefine colores. Tu .p10k.zsh sigue
# intacto: qué segmentos se muestran, iconos y separadores no se tocan aquí.
# Para volver al aspecto anterior basta comentar la línea que lo carga en .zshrc.

() {
  # ── Paleta Catppuccin Mocha ────────────────────────────────────────────────
  local rosewater='#f5e0dc' flamingo='#f2cdcd' pink='#f5c2e7' mauve='#cba6f7'
  local red='#f38ba8'       maroon='#eba0ac'   peach='#fab387' yellow='#f9e2af'
  local green='#a6e3a1'     teal='#94e2d5'     sky='#89dceb'   sapphire='#74c7ec'
  local blue='#89b4fa'      lavender='#b4befe' text='#cdd6f4'  subtext0='#a6adc8'
  local overlay0='#6c7086'  surface1='#45475a' surface0='#313244'

  # ── Directorio ─────────────────────────────────────────────────────────────
  typeset -g POWERLEVEL9K_DIR_FOREGROUND=$blue
  typeset -g POWERLEVEL9K_DIR_ANCHOR_FOREGROUND=$lavender
  typeset -g POWERLEVEL9K_DIR_SHORTENED_FOREGROUND=$overlay0
  typeset -g POWERLEVEL9K_DIR_ANCHOR_BOLD=true
  # Carpeta sin permiso de escritura y rutas especiales
  typeset -g POWERLEVEL9K_DIR_NOT_WRITABLE_FOREGROUND=$red
  typeset -g POWERLEVEL9K_DIR_ETC_FOREGROUND=$peach

  # ── Git (vcs) ──────────────────────────────────────────────────────────────
  typeset -g POWERLEVEL9K_VCS_CLEAN_FOREGROUND=$green        # limpio
  typeset -g POWERLEVEL9K_VCS_MODIFIED_FOREGROUND=$yellow    # con cambios
  typeset -g POWERLEVEL9K_VCS_UNTRACKED_FOREGROUND=$teal     # archivos nuevos
  typeset -g POWERLEVEL9K_VCS_CONFLICTED_FOREGROUND=$red     # conflictos
  typeset -g POWERLEVEL9K_VCS_LOADING_FOREGROUND=$overlay0

  # ── Símbolo del prompt ─────────────────────────────────────────────────────
  typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND=$green
  typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND=$red

  # ── Estado del último comando ──────────────────────────────────────────────
  typeset -g POWERLEVEL9K_STATUS_OK_FOREGROUND=$green
  typeset -g POWERLEVEL9K_STATUS_ERROR_FOREGROUND=$red
  typeset -g POWERLEVEL9K_STATUS_ERROR_SIGNAL_FOREGROUND=$maroon
  typeset -g POWERLEVEL9K_STATUS_ERROR_PIPE_FOREGROUND=$maroon

  # ── Duración del comando y trabajos en segundo plano ───────────────────────
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND=$peach
  typeset -g POWERLEVEL9K_BACKGROUND_JOBS_FOREGROUND=$sky

  # ── Entornos de lenguajes (derecha) ────────────────────────────────────────
  typeset -g POWERLEVEL9K_VIRTUALENV_FOREGROUND=$teal
  typeset -g POWERLEVEL9K_ANACONDA_FOREGROUND=$teal
  typeset -g POWERLEVEL9K_PYENV_FOREGROUND=$teal
  typeset -g POWERLEVEL9K_NODENV_FOREGROUND=$green
  typeset -g POWERLEVEL9K_NVM_FOREGROUND=$green
  typeset -g POWERLEVEL9K_NODEENV_FOREGROUND=$green
  typeset -g POWERLEVEL9K_GOENV_FOREGROUND=$sapphire
  typeset -g POWERLEVEL9K_ASDF_FOREGROUND=$mauve
  typeset -g POWERLEVEL9K_DIRENV_FOREGROUND=$yellow
  typeset -g POWERLEVEL9K_RBENV_FOREGROUND=$red
  typeset -g POWERLEVEL9K_JENV_FOREGROUND=$peach
  typeset -g POWERLEVEL9K_RUST_VERSION_FOREGROUND=$peach

  # ── Contexto (usuario@host) y hora ─────────────────────────────────────────
  typeset -g POWERLEVEL9K_CONTEXT_FOREGROUND=$subtext0
  typeset -g POWERLEVEL9K_CONTEXT_ROOT_FOREGROUND=$red
  typeset -g POWERLEVEL9K_TIME_FOREGROUND=$overlay0

  # ── Otros que puedas activar más adelante ──────────────────────────────────
  typeset -g POWERLEVEL9K_KUBECONTEXT_FOREGROUND=$sapphire
  typeset -g POWERLEVEL9K_AWS_FOREGROUND=$peach
  typeset -g POWERLEVEL9K_DOCKER_MACHINE_FOREGROUND=$sapphire
  typeset -g POWERLEVEL9K_BATTERY_CHARGING_FOREGROUND=$green
  typeset -g POWERLEVEL9K_BATTERY_LOW_FOREGROUND=$red
}
