{ pkgs, ... }:

{
  # home.pointerCursor = {
  #   package = pkgs.catppuccin-cursors.mochaLavender;
  #   name = "Catppuccin-Mocha-Lavender-Cursors";
  #   gtk.enable = true;
  # };

  gtk = {
    enable = true;
    # font = {
    #   package = (pkgs.nerdfonts.override { fonts = [ "Mononoki" ]; });
    #   name = "Mononoki Nerd Font Regular";
    #   size = 18;
    # };
    iconTheme = {
      package = (pkgs.catppuccin-papirus-folders.override { flavor = "mocha"; accent = "lavender"; });
      name  = "Papirus-Dark";
    };
    theme = {
      package = (pkgs.catppuccin-gtk.override { accents = [ "lavender" ]; size = "standard"; variant = "mocha"; });
      name = "Catppuccin-Mocha-Standard-Peach-Dark";
    };
  };
} 
