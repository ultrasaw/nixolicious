{ config, pkgs, lib, ... }:

{
  programs.waybar.enable = true;
  # programs.swaylock.enable = true;
  services.dunst.enable = true;

  wayland.windowManager.hyprland = {
    enable = true;

    settings = {

      "$mod" = "SUPER";

      bind = [
        "$mod, S, exec, rofi -show drun -show-icon"
      ];

      exec-once = "${pkgs.swaylock}/bin/swaylock --image ~Documents/Pictures/bin.jpg --indicator-idle-visible";
      # exec-once = "${pkgs.swaylock}/bin/swaylock";

    };
  };

  # services.hyprpaper = {
  #   enable = true;
  #   settings = {
  #     ipc = "on";
  #     splash = false;
  #     splash_offset = 2.0;

  #     preload =
  #       [ "~Documents/Pictures/bin.jpg" ];

  #     wallpaper = [
  #       "DP-1,~Documents/Pictures/bin.jpg}"
  #     ];
  #   }
  # };

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