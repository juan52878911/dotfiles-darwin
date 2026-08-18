# dotfiles

Configuración de terminal y editor, reproducible con nix-darwin + home-manager.

## Qué hay

| Ruta | Qué es |
|---|---|
| `config/nvim/` | Neovim sobre LazyVim, tema Catppuccin Mocha |
| `config/tmux/` | tmux + scripts (`nowplaying.sh`, `float-setup.sh`) |
| `config/kitty/` | kitty, Catppuccin Mocha |
| `home/` | zsh, powerlevel10k, markdownlint |
| `darwin/` | flake de nix-darwin y módulo de home-manager |

## Fuera del repo a propósito

- **Gestores de versiones imperativos** (SDKMAN, nvm, pyenv, rustup, bun): siguen
  instalándose a mano. Migrarlos a Nix es un proyecto aparte y hoy funcionan.
- **Diccionarios del corrector** (`config/nvim/spell/`): 24 MB regenerables.
- **Secretos**: ninguno. Las claves SSH y tokens no viven aquí.
