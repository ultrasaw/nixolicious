{ pkgs, ... }:

{

  home = {
    file = {
      # # Top Level Files symlinks
      # ".zshrc".source = ../../dotfiles/.zshrc;
      # ".zshenv".source = ../../dotfiles/.zshenv;
      
      # # Config directories
      ".config/alacritty".source = ../dotfiles/.config/alacritty;
      ".config/helix".source = ../dotfiles/.config/helix;
      ".config/starship.toml".source = ../dotfiles/.config/starship/starship.toml;
      # ".config/rstudio/themes".source = ../dotfiles/.config/rstudio/themes;
      ".config/zellij".source = ../dotfiles/.config/zellij;

      # still have to do 'chmod +x dotfiles/.config/zellij/scripts/fzf-hx-open.sh'
      ".config/zellij/scripts/fzf-hx-open.sh" = {
        text      = builtins.readFile ../dotfiles/.config/zellij/scripts/fzf-hx-open.sh;
        executable = true;
      };
    };
  };

  # home.pointerCursor = {
  #   package = pkgs.catppuccin-cursors.mochaLavender;
  #   name = "Catppuccin-Mocha-Lavender-Cursors";
  #   gtk.enable = true;
  # };

  # gtk = {
  #   enable = true;
  #   # font = {
  #   #   package = (pkgs.nerdfonts.override { fonts = [ "Mononoki" ]; });
  #   #   name = "Mononoki Nerd Font Regular";
  #   #   size = 18;
  #   # };
  #   iconTheme = {
  #     package = (pkgs.catppuccin-papirus-folders.override { flavor = "mocha"; accent = "lavender"; });
  #     name  = "Papirus-Dark";
  #   };
  #   theme = {
  #     package = (pkgs.catppuccin-gtk.override { accents = [ "lavender" ]; size = "standard"; variant = "mocha"; });
  #     name = "Catppuccin-Mocha-Standard-Peach-Dark";
  #   };
  # };
} 
