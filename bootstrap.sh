#!/bin/bash
# De un Mac vacío a los dotfiles funcionando. Idempotente: se puede repetir.
#   curl -fsSL https://raw.githubusercontent.com/juan52878911/dotfiles-darwin/main/bootstrap.sh | bash
set -euo pipefail
DOTFILES="${DOTFILES:-$HOME/dotfiles}"
paso() { printf '\n\033[1;35m▸ %s\033[0m\n' "$*"; }

paso "Herramientas de línea de comandos de Xcode"
xcode-select -p >/dev/null 2>&1 || { xcode-select --install; read -rp "Pulsa Enter cuando termine la instalación… "; }

paso "Nix (Determinate)"
if ! command -v nix >/dev/null 2>&1 && [ ! -x /nix/var/nix/profiles/default/bin/nix ]; then
  curl -fsSL https://install.determinate.systems/nix | sh -s -- install --determinate --no-confirm
fi
export PATH="/nix/var/nix/profiles/default/bin:$PATH"

paso "Homebrew (nix-darwin no lo instala; lo siguen usando nvm, pyenv y apps)"
if ! command -v brew >/dev/null 2>&1 && [ ! -x /opt/homebrew/bin/brew ]; then
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

paso "dotfiles en $DOTFILES (con el submódulo privado si tienes acceso)"
if [ ! -d "$DOTFILES/.git" ]; then
  git clone https://github.com/juan52878911/dotfiles-darwin.git "$DOTFILES"
fi
git -C "$DOTFILES" submodule update --init 2>/dev/null \
  || echo "  (sin acceso a dotfiles-privado: ws quedará en modo normal)"

paso "nix-darwin + home-manager"
host="$(scutil --get LocalHostName)"
if ! nix eval "$DOTFILES#darwinConfigurations.\"$host\".system.drvPath" >/dev/null 2>&1; then
  echo "  No hay configuración para «$host»: añádelo en flake.nix (darwinConfigurations)."
  exit 1
fi
if [ -x /run/current-system/sw/bin/darwin-rebuild ]; then
  sudo /run/current-system/sw/bin/darwin-rebuild switch --flake "$DOTFILES"
else
  sudo nix run nix-darwin -- switch --flake "$DOTFILES"
fi

paso "Listo. Pasos manuales, una vez por máquina:"
cat <<'MSG'
  • Secretos de ws en el Llavero:  security add-generic-password -s ws/<NOMBRE> -w
    (los que aparezcan como ${NOMBRE} en private/ws/ws.toml)
  • gh personal:                   gh auth login
  • Cuentas de cada organización:  en tmux, prefix + s → organización → ^g
  • Plugins de tmux:               prefix + I
  • Comprobación:                  ws doctor
MSG
