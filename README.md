# dotfiles

Configuración de terminal y editor, reproducible con nix-darwin + home-manager.

## Instalar

```sh
git clone --recurse-submodules https://github.com/juan52878911/dotfiles-darwin ~/dotfiles
sudo darwin-rebuild switch --flake ~/dotfiles#MacBook-Pro-de-Juan
```

`private/` es un submódulo privado ([dotfiles-privado](https://github.com/juan52878911/dotfiles-privado))
con la configuración que no debe ser pública: las organizaciones de
[tmux-ws](https://github.com/juan52878911/tmux-ws) (cuentas, correos, clientes). Desde
mi cuenta se clona con todo; sin acceso, el submódulo no baja y el resto funciona
igual (ws queda en modo normal). Si ya clonaste sin él: `git submodule update --init`.

Después, una vez por máquina: los secretos de ws en el Llavero (`security
add-generic-password -s ws/<NOMBRE> -w`) y los logins por organización desde el
selector de tmux (`prefix + s`, `^g`).

## ws: organizaciones (Trycore, Aura…) en el día a día

Detalle completo en el [README de tmux-ws](https://github.com/juan52878911/tmux-ws#usage).

- `prefix + s`: selector de sesiones por organización. `enter` abrir · `^n` nueva ·
  `^x` cerrar (`s`/`n`) · `^r` renombrar · `^e` editar `ws.toml` · `^g` conectar GitHub ·
  `/` buscar. Desde una flotante la cierra y la reabre al volver.
- `prefix + S`: nueva sesión normal, o dentro de una organización (crea proyectos y organizaciones).
- En la carpeta de un proyecto, `claude`, `gh`, `git` y `opencode` usan solos la cuenta de su
  organización. Un repo clonado de `trycore-co` o `Aura-CRM` se registra solo al entrar.
- La configuración está en `private/ws/ws.toml` (submódulo privado) y la interfaz, en español
  (`@ws-lang es` en `config/tmux/tmux.conf`).
- Diagnóstico: `ws doctor`. Saltarse ws una vez: `WS_OFF=1 claude`.
- Actualizar el plugin: `nix flake update tmux-ws` y `darwin-rebuild switch`.

## Qué hay

| Ruta | Qué es |
|---|---|
| `config/nvim/` | Neovim sobre LazyVim, tema Catppuccin Mocha |
| `config/tmux/` | tmux + scripts (`nowplaying.sh`, `float-setup.sh`, `float-open.sh`, `remote-session.sh`) |
| `config/kitty/` | kitty, Catppuccin Mocha |
| `home/` | zsh, powerlevel10k, markdownlint, git, direnv |
| `darwin/` | flake de nix-darwin y módulo de home-manager |
| `private/` | submódulo privado: configuración de ws |
| tmux-ws | input del flake: organizaciones y espacios de trabajo (`programs.ws`) |

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
