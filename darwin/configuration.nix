# Configuración de sistema (nix-darwin).
#
# Deliberadamente MÍNIMA: este Mac tiene Homebrew, SDKMAN, nvm, pyenv, rustup y
# bun gestionando sus propias herramientas, y todo eso funciona. Migrarlos a Nix
# es un proyecto aparte con riesgo real, así que aquí solo se declaran las
# herramientas de terminal que ya usamos y ningún ajuste destructivo del sistema.
{ pkgs, usuario, ... }:
{
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Este Mac usa Determinate Nix, que trae su propio daemon para gestionar la
  # instalación de Nix. nix-darwin intenta gestionarla también y aborta la
  # activación por el conflicto. Cediéndole el control a Determinate se resuelve.
  # Contrapartida: las opciones `nix.*` (ajustes del daemon, builder de Linux)
  # dejan de estar disponibles desde aquí; se configuran en Determinate.
  nix.enable = false;

  # El usuario que gestiona home-manager
  users.users.${usuario}.home = "/Users/${usuario}";

  # Herramientas de terminal (las mismas que hoy vienen de Homebrew).
  # Ojo: NO se quitan de Homebrew automáticamente; conviven hasta que decidas.
  environment.systemPackages = with pkgs; [
    fzf
    zoxide
    atuin
    carapace
    bat
    eza
    fd
    ripgrep
    figlet
    autossh
    mutagen
  ];

  # nix-darwin NO gestiona los archivos de shell del sistema.
  #
  # Con `nix.enable = false` (Determinate lleva Nix), nix-darwin reescribiría
  # /etc/zshrc y /etc/bashrc SIN la línea que carga el daemon de Nix — que hoy
  # está justo ahí. Resultado: `nix` dejaría de existir en cada shell nueva.
  # Además /etc/bashrc ya tenía contenido propio y la activación abortaba.
  # Tu configuración de zsh vive entera en ~/.zshrc, que gestiona home-manager,
  # así que no se pierde nada dejando /etc como está.
  programs.zsh.enable = false;
  programs.bash.enable = false;

  # Necesario para que `nix-darwin` sepa desde qué versión migra
  system.stateVersion = 5;
  system.primaryUser = usuario;
}
