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
    direnv
    nix-direnv
    autossh
    mutagen
    delta # pager de git (home/gitconfig): diffs coloreados con números de línea
    # Plugins de zsh desde Nix (antes: un clon suelto en ~/powerlevel10k y Homebrew)
    zsh-powerlevel10k
    zsh-autosuggestions
    zsh-syntax-highlighting
    # Nix en Neovim: servidor de lenguaje y formateador (lang.nix de LazyVim)
    nil
    nixfmt-rfc-style
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

  # Los plugins de zsh quedan en /run/current-system/sw/share/<plugin>/ (zshrc
  # los busca ahí primero); nix-darwin solo enlaza las carpetas que se le piden.
  environment.pathsToLink = [
    "/share/zsh-powerlevel10k"
    "/share/zsh-autosuggestions"
    "/share/zsh-syntax-highlighting"
  ];

  # ─── Ajustes de macOS ───────────────────────────────────────────────────────
  # Los valores que ya tenía este Mac (leídos con `defaults read` el 2026-10-10),
  # para que uno nuevo quede igual. Solo lo que estaba puesto a propósito.
  system.defaults = {
    dock = {
      autohide = true;
      tilesize = 41;
      show-recents = true;
      magnification = true;
    };
    finder.FXPreferredViewStyle = "Nlsv"; # vista de lista
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      KeyRepeat = 2;
      InitialKeyRepeat = 15;
      NSAutomaticCapitalizationEnabled = true;
      "com.apple.swipescrolldirection" = false; # desplazamiento natural: no
    };
    trackpad.Clicking = false; # sin tocar para hacer clic
  };

  # ─── Homebrew, declarado ────────────────────────────────────────────────────
  # nix-darwin no instala Homebrew (lo hace bootstrap.sh), pero sí lo gestiona:
  # en un Mac nuevo, el switch instala esta lista. En este, no toca nada:
  #   - cleanup = "none": jamás desinstala lo que no esté aquí;
  #   - autoUpdate/upgrade = false: no actualiza en cada switch.
  # Lo que ya viene de Nix (fzf, bat, eza, fd, ripgrep, zoxide, atuin, carapace,
  # figlet, autossh, delta y los plugins de zsh) no se repite aquí.
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = false;
      upgrade = false;
      cleanup = "none";
    };
    taps = [
      "hashicorp/tap"
      "lizardbyte/homebrew"
      "mutagen-io/mutagen"
      "spring-attic/spring-cli"
    ];
    brews = [
      "act"
      "actionlint"
      "aircrack-ng"
      "arduino-cli"
      "arp-scan"
      "automake"
      "awscli"
      "btop"
      "ccache"
      "cdrtools"
      "cmake"
      "cmatrix"
      "d2"
      "displayplacer"
      "docker"
      "e2fsprogs"
      "espeak-ng"
      "fastfetch"
      "fish"
      "flac"
      "gcc"
      "gemini-cli"
      "gh"
      "git"
      "git-xet"
      "gnu-sed"
      "gnu-tar"
      "go"
      "gogcli"
      "grpcurl"
      "hashcat"
      "hashicorp/tap/terraform"
      "hcxtools"
      "htop"
      "imagemagick"
      "k6"
      "lazydocker"
      "lazygit"
      "lazyssh"
      "libiconv"
      "librsvg"
      "lima"
      "lizardbyte/homebrew/sunshine"
      "llama.cpp"
      "llvm@21"
      "maven"
      "mutagen-io/mutagen/mutagen"
      "neovim"
      "ninja"
      "nmap"
      "nowplaying-cli"
      "nvm"
      "ollama"
      "openfortivpn"
      "opentofu"
      "p7zip"
      "pipx"
      "pyenv-virtualenv"
      "python@3.13"
      "qemu"
      "rsync"
      "ruby"
      "rust"
      "rustup"
      "scrcpy"
      "sevenzip"
      "shpotify"
      "socat"
      "spicetify-cli"
      "sshpass"
      "tcpdump"
      "terminal-notifier"
      "tmux"
      "unar"
      "vhs"
      "whisper.cpp"
      "zsh"
    ];
    casks = [
      "android-commandlinetools"
      "android-platform-tools"
      "anki"
      "betterdisplay"
      "bitwarden"
      "claude-code"
      "crossover"
      "docker-desktop"
      "flameshot"
      "font-iosevka-term-nerd-font"
      "font-symbols-only-nerd-font"
      "hiddenbar"
      "kitty"
      "microsoft-auto-update"
      "microsoft-outlook"
      "monitorcontrol"
      "multipass"
      "ngrok"
      "obsidian"
      "rar"
      "slack"
      "spotify"
      "utm"
      "vorssaint"
    ];
  };

  # Necesario para que `nix-darwin` sepa desde qué versión migra
  system.stateVersion = 5;
  system.primaryUser = usuario;
}
