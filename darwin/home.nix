# home-manager: enlaza los dotfiles del repo a su sitio en $HOME.
#
# Usa mkOutOfStoreSymlink en vez de copiar al store de Nix. Así los archivos
# siguen siendo editables en el repo y los cambios se ven al instante, sin un
# `darwin-rebuild` por cada retoque de la config de tmux o Neovim.
{ config, pkgs, usuario, ... }:
let
  repo = "/Users/${usuario}/dotfiles";
  enlace = ruta: config.lib.file.mkOutOfStoreSymlink "${repo}/${ruta}";
in
{
  home.stateVersion = "24.05";

  home.file = {
    # zsh y prompt
    ".zshrc".source = enlace "home/zshrc";
    ".p10k.zsh".source = enlace "home/p10k.zsh";
    ".p10k.catppuccin.zsh".source = enlace "home/p10k.catppuccin.zsh";
    ".markdownlint-cli2.jsonc".source = enlace "home/markdownlint-cli2.jsonc";

    # tmux (el conf va en $HOME; los scripts en .config)
    ".tmux.conf".source = enlace "config/tmux/tmux.conf";
  };

  xdg.configFile = {
    "nvim".source = enlace "config/nvim";
    "kitty/kitty.conf".source = enlace "config/kitty/kitty.conf";
    "tmux/scripts".source = enlace "config/tmux/scripts";
  };
}
