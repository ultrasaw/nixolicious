{
  config,
  lib,
  pkgs,
  ...
}:

{

  home = {
    file = {
      # # Top Level Files symlinks
      # ".zshrc".source = ../../dotfiles/.zshrc;
      # ".zshenv".source = ../../dotfiles/.zshenv;
      
      # # Config directories
      # ".config/alacritty".source = ../../dotfiles/.config/alacritty;
      # ".config/dunst".source = ../../dotfiles/.config/dunst;
      # ".config/tmux/tmux.conf".source = ../../dotfiles/.config/tmux/tmux.conf;
      ".config/waybar".source = ../dotfiles/.config/waybar;
    };
  };

  programs.waybar = {

    enable = true;
    systemd = {
      enable = false; # disable it, autostart it in hyprland conf
      target = "graphical-session.target";
    };
  };
}
