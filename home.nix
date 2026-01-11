{
  config,
  pkgs,
  lib,
  ...
}:

{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "shar";
  home.homeDirectory = "/Users/shar";
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "vscode"
  ];

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "25.05"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    neovim
    ffmpeg
    tealdeer
    starship
    eza
    bat
    ripgrep
    fastfetch
    fd
    btop
    nerd-fonts.jetbrains-mono
    sdcv
    stow
    nodejs_24
    librewolf
    vscode

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';

    ".config/stardict/dic" = {
      source = ./stardict;
      #recursive = true;
    };
    ".config/starship.toml".source = ./dotfiles/starship/.config/starship.toml;
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/shar/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    EDITOR = "nvim";
    STARDICT_DATA_DIR = "$HOME/.config/stardict";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    historySubstringSearch.enable = true;
    defaultKeymap = "viins";
    history = {
      append = true;
      expireDuplicatesFirst = true;
      extended = true;
      findNoDups = true;
      ignoreAllDups = false;
      ignoreDups = true;
      ignoreSpace = true;
      save = 10000;
      saveNoDups = false;
      share = true;
      size = 10000;
    };
    initContent = ''
      alias ..='cd ..'
      alias ...='cd ../..'
      alias ....='cd ../../..'
      alias ~='cd ~'

      eval "$(starship init zsh)"
    '';
    shellAliases = {
      l = "eza";
      ll = "eza -lhF --git";
      la = "eza -lahF --git";
      lt = "eza -l --tree --git";
      lat = "eza -la --tree --git";

      gs = "git status";
      gd = "git diff";
      gc = "git commit";
      gco = "git checkout";
      gp = "git push";
      gl = "git log --oneline --graph --decorate";

      c = "clear";
      h = "history";
      please = "sudo";

      # update = "nix flake update && home-manager switch";

      vi = "nvim";
      grep = "grep --color=auto";

      # df = "df -h";
      # du = "du -h --max-depth=1";
      # path = "echo -e ${PATH//:/\\n}";
      icat = "kitty +kitten icat";
    };
  };

  programs.kitty = {
    enable = true;
    shellIntegration.enableZshIntegration = true;
    font = {
      name = "JetBrainsMono Nerd Font Mono";
      size = 16;
    };
    themeFile = "Argonaut";
    extraConfig = ''
      window_padding_width 10.0
    '';
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.git = {
    enable = true;
    settings.user.email = "sharavananpa@gmail.com";
    settings.user.name = "Sharavanan Balasundaravel";
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
  };
}
