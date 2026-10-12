# home-manager: enlaza los dotfiles del repo a su sitio en $HOME.
#
# Usa mkOutOfStoreSymlink en vez de copiar al store de Nix. Así los archivos
# siguen siendo editables en el repo y los cambios se ven al instante, sin un
# `darwin-rebuild` por cada retoque de la config de tmux o Neovim.
{ config, pkgs, usuario, nixpkgs, tmux-ws, nod, ... }:
let
  repo = "/Users/${usuario}/dotfiles";
  enlace = ruta: config.lib.file.mkOutOfStoreSymlink "${repo}/${ruta}";

  # Pasa los `export` de home/entorno-gui.sh (y private/entorno-gui.sh) a launchd.
  # Se evalúan en un entorno vacío para que sólo suba lo que declaran los archivos.
  entornoGui = pkgs.writeShellScript "entorno-gui" ''
    archivos=("${repo}/home/entorno-gui.sh" "${repo}/private/entorno-gui.sh")
    while IFS= read -r -d "" par; do
      nombre=''${par%%=*}
      case $nombre in HOME|USER|PWD|OLDPWD|SHLVL|_) continue ;; esac
      /bin/launchctl setenv "$nombre" "''${par#*=}"
    done < <(/usr/bin/env -i HOME="$HOME" USER="$USER" ${pkgs.bash}/bin/bash -c '
      for f in "$@"; do [ -f "$f" ] && . "$f"; done
      /usr/bin/env -0' _ "''${archivos[@]}")
  '';
in
{
  home.stateVersion = "24.05";

  # TPM (plugins de tmux): en un Mac nuevo no existe y tmux.conf lo carga al
  # final. Se clona una vez; luego `prefix + I` instala el resto de plugins.
  home.activation.tpm = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
      ${pkgs.git}/bin/git clone --depth 1 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm" || true
    fi
  '';

  # ws: organizaciones y espacios de trabajo (github.com/juan52878911/tmux-ws).
  # La config (ws.toml, orgs/) vive en el submódulo privado private/; el tema, en config/tmux/tmux.conf.
  # Para desarrollar ws sin rebuild: checkout = "/Users/${usuario}/Documents/GitHub/tmux-ws";
  imports = [ tmux-ws.homeManagerModules.default nod.homeManagerModules.default ];
  programs.ws = {
    enable = true;
    configDir = "${repo}/private/ws";   # submódulo privado (dotfiles-privado)
    nixpkgs = "github:NixOS/nixpkgs/${nixpkgs.rev}";
  };

  # Nod (github.com/juan52878911/nod): observa las sesiones de Claude Code (eventos Nod v1) en ~/.claude y en
  # todos los perfiles de ws, también en los que se creen después. Reintentar a mano: nod-sync. Orbit (el
  # reloj) se alimenta de Nod; su servidor se instala aparte (tools/install/install-mac.sh del repo Orbit).
  programs.nod.enable = true;
  # Collector de Nod en este Mac (launchd, 127.0.0.1:8787): guarda los eventos y calcula las métricas
  # (`nod-collector report`). `tmux` deja el binario para el panel de límites (config/tmux/scripts/nod-limits.sh).
  programs.nod.collector = {
    enable = true;
    tmux = true;
  };
  # Adónde van los eventos y quién puede aprobar (~/.config/nod/config.json): el fichero local, el collector y
  # el servidor de Orbit (el reloj), que además es el controlador de Nod Control. El token lo deja el
  # instalador de Orbit en un fichero 0600; aquí solo va su ruta.
  programs.nod.settings =
    let
      orbit = {
        url = "http://127.0.0.1:7878";
        token_file = "~/Library/Application Support/Orbit/nod.token";
      };
    in
    {
      sinks = [
        { file = "~/.local/state/nod/events.jsonl"; }
        { url = "http://127.0.0.1:8787"; }
        orbit
      ];
      control = orbit;
    };
  # Nod también en OpenCode (plugin en ~/.config/opencode/plugins/nod.js).
  programs.nod.opencode.enable = true;

  # Entorno de las apps de escritorio: ver home/entorno-gui.sh.
  # Corre al iniciar sesión y cada vez que se guarda uno de los dos archivos.
  launchd.agents.entorno-gui = {
    enable = true;
    config = {
      ProgramArguments = [ "${entornoGui}" ];
      RunAtLoad = true;
      WatchPaths = [ "${repo}/home/entorno-gui.sh" "${repo}/private/entorno-gui.sh" ];
    };
  };

  # Etiquetas de Finder de las carpetas de cada organización de ws (ver
  # darwin/ws-etiquetas.py). Integración con macOS: vive aquí, no en el plugin.
  launchd.agents.ws-etiquetas = {
    enable = true;
    config = {
      ProgramArguments = [ "${pkgs.python3}/bin/python3" "${repo}/darwin/ws-etiquetas.py"
                           "${repo}/private/ws/ws.toml" ];
      RunAtLoad = true;
      WatchPaths = [ "${repo}/private/ws" ];  # la carpeta: ws escribe con temporal + rename
    };
  };

  home.file = {
    # Navegador de los logins de ws: Zen en el contenedor de cada organización.
    ".local/bin/zen-ws" = {
      executable = true;
      text = ''
        #!/bin/sh
        exec ${pkgs.python3}/bin/python3 ${repo}/darwin/zen-ws.py "$@"
      '';
    };

    # zsh y prompt
    ".zshrc".source = enlace "home/zshrc";
    ".p10k.zsh".source = enlace "home/p10k.zsh";
    ".p10k.catppuccin.zsh".source = enlace "home/p10k.catppuccin.zsh";
    ".markdownlint-cli2.jsonc".source = enlace "home/markdownlint-cli2.jsonc";

    # tmux (el conf va en $HOME; los scripts en .config)
    ".tmux.conf".source = enlace "config/tmux/tmux.conf";

    # git. La identidad y los filtros de LFS; el ignore global va en .config.
    ".gitconfig".source = enlace "home/gitconfig";
  };

  xdg.configFile = {
    "direnv/direnvrc".source = enlace "home/direnvrc";
    "nvim".source = enlace "config/nvim";
    "kitty/kitty.conf".source = enlace "config/kitty/kitty.conf";
    "tmux/scripts".source = enlace "config/tmux/scripts";

    "git/ignore".source = enlace "config/git/ignore";
    "atuin/config.toml".source = enlace "config/atuin/config.toml";

    # De gh sólo config.yml. hosts.yml NO: guarda el token de OAuth en claro.
    "gh/config.yml".source = enlace "config/gh/config.yml";

    # btop y htop reescriben su propio archivo al salir. Con mkOutOfStoreSymlink
    # esa escritura aterriza en el repo, así que los ajustes que hagas desde la
    # TUI se versionan solos. La contrapartida es que `git status` sale sucio
    # cada vez que abres y cierras cualquiera de los dos.
    "btop/btop.conf".source = enlace "config/btop/btop.conf";
    "htop/htoprc".source = enlace "config/htop/htoprc";

    # De opencode sólo los agentes y comandos, que son markdown limpio.
    # opencode.json queda fuera: lleva la API key de Obsidian dentro.
    "opencode/agent".source = enlace "config/opencode/agent";
    "opencode/commands".source = enlace "config/opencode/commands";
  };
}
