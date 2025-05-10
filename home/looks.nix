{ pkgs, config, ... }:

{

  # home = {
  #   file = {
  #     # # Top Level Files symlinks
  #     # ".zshrc".source = ../../dotfiles/.zshrc;
  #     # ".zshenv".source = ../../dotfiles/.zshenv;
      
  #     # # Config directories
  #     ".config/alacritty".source = ../dotfiles/.config/alacritty;
  #     ".config/helix".source = ../dotfiles/.config/helix;
  #     ".config/niri".source = ../dotfiles/.config/niri;
  #     ".config/starship.toml".source = ../dotfiles/.config/starship/starship.toml;
  #     # ".config/rstudio/themes".source = ../dotfiles/.config/rstudio/themes;
  #     ".config/waybar".source = ../dotfiles/.config/waybar;
  #     ".config/swappy".source = ../dotfiles/.config/swappy;
  #     ".config/zellij".source = ../dotfiles/.config/zellij;

  #     # still have to do 'chmod +x dotfiles/.config/zellij/scripts/fzf-hx-open.sh'
  #     ".config/zellij/scripts/fzf-hx-open.sh" = {
  #       text      = builtins.readFile ../dotfiles/.config/zellij/scripts/fzf-hx-open.sh;
  #       executable = true;
  #     };
  #   };
  # };

  home.file."${config.xdg.configHome}" = {
    source = ../dotfiles;
    recursive = true;
  };

  # home.pointerCursor = {
  #   package = pkgs.catppuccin-cursors.mochaLavender;
  #   name = "Catppuccin-Mocha-Lavender-Cursors";
  #   # gtk.enable = true;
  # };

  # dconf = {
  #   enable = true;
  #   settings = {
  #     "org/gnome/desktop/interface" = { color-scheme = "prefer-dark"; };
  #   };
  # };

  gtk = {
    enable = true;

    # iconTheme = {
    #   package = pkgs.whitesur-icon-theme;
    #   name    = "WhiteSur";
    # };

    iconTheme = {
      package = (pkgs.catppuccin-papirus-folders.override { flavor = "mocha"; accent = "lavender"; });
      name  = "Papirus-Dark";
    };
    
    cursorTheme = {
      # package = pkgs.bibata-cursors;
      # name = "Bibata-Modern-Classic";

      package = pkgs.gnome.adwaita-icon-theme;
      name = "Adwaita";
    };
  };

  gtk = {
    theme = {
      name = "Andromeda";
      package = pkgs.andromeda-gtk-theme;
    };
  };

  # gtk = {
  #   theme = {
  #     name = "Nordic-darker";
  #     package = pkgs.nordic;
  #   };
  # };

  # gtk = {
  #   enable = true;

  #   iconTheme = {
  #     package = pkgs.whitesur-icon-theme;
  #     name    = "WhiteSur";
  #   };

  #   theme = {
  #     package = pkgs.catppuccin-gtk.override {
  #       accents = [ "lavender" ];
  #       size = "standard";
  #       variant = "mocha";
  #     };
  #     name = "catppuccin-mocha-lavender-standard";
  #   };
  # };
}
