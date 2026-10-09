# home-manager: enlaza los dotfiles del repo a su sitio en $HOME.
#
# Usa mkOutOfStoreSymlink en vez de copiar al store de Nix. Así los archivos
# siguen siendo editables en el repo y los cambios se ven al instante, sin un
# `darwin-rebuild` por cada retoque de la config de tmux o Neovim.
{ config, pkgs, usuario, nixpkgs, tmux-ws, ... }:
let
  repo = "/Users/${usuario}/dotfiles";
  enlace = ruta: config.lib.file.mkOutOfStoreSymlink "${repo}/${ruta}";
in
{
  home.stateVersion = "24.05";

  # ws: organizaciones y espacios de trabajo (github.com/juan52878911/tmux-ws).
  # La config (ws.toml, orgs/) vive en el submódulo privado private/; el tema, en config/tmux/tmux.conf.
  # Para desarrollar ws sin rebuild: checkout = "/Users/${usuario}/Documents/GitHub/tmux-ws";
  imports = [ tmux-ws.homeManagerModules.default ];
  programs.ws = {
    enable = true;
    configDir = "${repo}/private/ws";   # submódulo privado (dotfiles-privado)
    nixpkgs = "github:NixOS/nixpkgs/${nixpkgs.rev}";
  };

  home.file = {
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
