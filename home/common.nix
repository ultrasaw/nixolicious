{ config, pkgs, lib, ... }:

{
  home.username = "gio";
  home.homeDirectory = "/home/gio";

  home.stateVersion = "24.11";

  programs = {
    home-manager.enable = true;
    yazi.enable = true; # terminal file manager
  };

  # Enable Visual Studio Code with extensions
  programs.vscode = {
    enable = true;
     extensions = with pkgs.vscode-extensions; [
      bbenoist.nix
      golang.go
      ms-python.python
      github.github-vscode-theme
      vscodevim.vim
      yzhang.markdown-all-in-one
      tamasfe.even-better-toml
      tal7aouy.icons
     ];
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      ll = "ls -l";
      vim = "nvim";
      update = "sudo nixos-rebuild switch";

      # Git Aliases
      ga = "git add";
      gc = "git commit";
      gp = "git push";

      # Other Aliases
      ld = "lazydocker";
      docker-clean = "docker container prune -f && docker image prune -f && docker network prune -f && docker volume prune -f";
      cr = "cargo run";
      battery = "upower -i /org/freedesktop/UPower/devices/battery_BAT1";
      y = "yazi";
    };

    history = {
      size = 10000;
      path = "${config.xdg.dataHome}/zsh/zsh_history";
    };

    oh-my-zsh = {
      enable = false;
      plugins = [ ];
      theme = "agnoster";
    };
  };

  programs.git = {
    enable = true;
    aliases = {
      pu = "push";
      co = "checkout";
      cm = "commit";
    };
  };

  # Define user environment packages
  home.packages = with pkgs; [
    htop
    alacritty
    neovim
    google-chrome
    firefox

    grim
    slurp
    swappy
    wl-clipboard

    nwg-bar

    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
  ];

  fonts.fontconfig.enable = true;

}
