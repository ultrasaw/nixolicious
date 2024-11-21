{ config, pkgs, lib, ... }:

{
  # programs.waybar.enable = true;
  services.dunst.enable = true;

  wayland.windowManager.hyprland = {
    enable = true;

    settings = {

      "$mod" = "SUPER";

      bind = [
        "$mod, S, exec, rofi -show drun -show-icon"
      ];

      exec-once = [
        "${pkgs.swaylock}/bin/swaylock --image ${config.home.homeDirectory}/Pictures/bin.jpg --indicator-idle-visible"
        "hyprctl setcursor Future-Cyan-Hyprcursor_Theme 40"
        ];

      # https://gitlab.com/Pummelfisch/future-cyan-hyprcursor
      env = [
        "HYPRCURSOR_THEME,Future-Cyan-Hyprcursor_Theme"
      ];
    };
  };

  services.hyprpaper = {
    enable = true;
    settings = {
      ipc = "on";
      splash = false;
      splash_offset = 2.0;

      preload =
        [ "~/Pictures/bin.jpg" ];

      wallpaper = [
        "HDMI-A-2,~/Pictures/bin.jpg"
      ];
    };
  };

}


# let
#   startupScript = ''
#     ${pkgs.waybar}/bin/waybar &
#     ${pkgs.swww}/bin/swww init &

#     sleep 1

#     ${pkgs.swww}/bin/swww img ${./wallpaper.png} &
#   '';
# in {
#   wayland.windowManager.hyprland = {
#     settings = {
#       exec-once = startupScript;
#       "$mod" = "SUPER";
#       bind = [
#         "$mod, S, exec, rofi -show drun -show-icon"
#       ];
#     };
#   };