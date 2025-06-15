{ pkgs, config, ... }:

{
  home.file."${config.xdg.configHome}" = {
    source = ../dotfiles;
    recursive = true;
  };

  gtk = {
    enable = true;

    theme = {
      name = "Andromeda";
      package = pkgs.andromeda-gtk-theme;
    };

    iconTheme = {
      package = pkgs.papirus-icon-theme;
      name = "Papirus-Dark";
    };

    cursorTheme = {
      package = pkgs.adwaita-icon-theme;
      name = "Adwaita";
    };
  };
}
