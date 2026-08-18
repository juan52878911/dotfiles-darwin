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

## Versiones de lenguajes: Nix por proyecto, gestores para lo global

**Por proyecto** — copia una plantilla y direnv hace el resto:

```sh
cd mi-proyecto && nx-py     # o nx-node / nx-rust
```

Crea `flake.nix` + `.envrc`. Al entrar en la carpeta se cargan esas versiones; al
salir, se descargan. Reproducible en cualquier máquina con Nix.

**Global** — siguen SDKMAN, nvm, pyenv, rustup y bun. No es pereza: nixpkgs **no
puede reproducir** el conjunto actual, comprobado versión por versión:

| Herramienta | Instalada | En nixpkgs |
|---|---|---|
| Node 20 | v20.19.5 | **no existe** (EOL, retirada de unstable) |
| Python | 3.13.11 | 3.13.14 |
| Bun | 1.3.4 | 1.3.13 |
| Java | 21.0.2-graalce | 21.0.11 (otro fabricante) |
| GraalVM CE | sí | no está con ese nombre |

Node 20 es el caso serio: es la versión por defecto y ahí viven los paquetes npm
globales `claude-auto-retry`, `pm2` y `ng`. Quitar nvm **rompería el comando `claude`**,
cuya ruta al launcher está fijada en el `.zshrc`.

Migrar del todo también implicaría renunciar a las 9 versiones de Java, 3 de Node y 2
de Python que hay instaladas, o empaquetar cada una a mano con overlays.
- **Diccionarios del corrector** (`config/nvim/spell/`): 24 MB regenerables.
- **Secretos**: ninguno. Las claves SSH y tokens no viven aquí.
