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
  };
}
