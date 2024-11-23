{ lib, ... }:
with lib;
{
  options.vars = {
    user = mkOption {
      type = types.str;
      default = "gio";
    };
    wallpaper = mkOption {
      type = types.str;
      default = "${../../assets/bin.jpg}";
      description = "wallpaper path";
    };
    base16Scheme = mkOption {
      type = types.attrsOf types.str;
      default = {
        base00 = "181818"; # Very dark gray
        base01 = "202020"; # Darker gray
        base02 = "282828"; # Dark gray
        base03 = "5a5a5a"; # Medium gray
        base04 = "7a7a7a"; # Light gray
        base05 = "d0d0d0"; # Soft light gray
        base06 = "d0d0d0"; # Same as base05
        base07 = "3c3c3c"; # Medium-dark gray
        base08 = "d75f5f"; # Muted red
        base09 = "ffaf5f"; # Warm muted orange
        base0A = "d78787"; # Subtle pinkish tan
        base0B = "87afaf"; # Muted teal
        base0C = "87d7d7"; # Soft aqua
        base0D = "87afd7"; # Muted blue
        base0E = "af87d7"; # Soft purple (reduced intensity)
        base0F = "3c3c3c"; # Same as base07, medium-dark gray
      };
      description = "base16 color scheme";
    };
  };
}
