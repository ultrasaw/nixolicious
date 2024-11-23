{ config, lib, pkgs, ... }:

{
stylix = {
  enable = true;
  autoEnable = true;
  image = config.vars.wallpaper;
  base16Scheme = config.vars.base16Scheme;
  cursor = {
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 24;
    };
  targets = {
    gnome.enable = true;
    gtk.enable = true;
    };
  polarity = "dark";
  };
}
