# Entorno de las apps de escritorio (Obsidian, editores, cualquier .app).
#
# Las apps que se abren desde el Dock, Finder o Spotlight no leen ~/.zshrc:
# heredan el entorno de launchd, cuyo PATH es /usr/bin:/bin:/usr/sbin:/sbin.
# Sin Nix ni Homebrew, git no encuentra `gh` y el helper de credenciales de ws
# falla (Obsidian Git pide usuario y clave).
#
# El agente `entorno-gui` (darwin/home.nix) carga este archivo al iniciar sesión
# y cada vez que se guarda, y pasa cada `export` a launchd con `launchctl setenv`.
# Las apps ya abiertas no se enteran: hay que cerrarlas y volver a abrirlas.
#
# Es un script de bash, así que vale $HOME. Este repo es público: los secretos
# van en private/entorno-gui.sh (se carga después de este si existe).

export PATH="$HOME/.local/share/ws/shims:/etc/profiles/per-user/$USER/bin:$HOME/.nix-profile/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/opt/homebrew/bin:/opt/homebrew/sbin:$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
