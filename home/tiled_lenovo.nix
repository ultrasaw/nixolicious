{ config, pkgs, lib, inputs, system, ... }:

{
  # programs.waybar.enable = true;
  services.dunst.enable = true;

  wayland.windowManager.hyprland = {
    enable = true;
    # monitor = "eDP-1, 1920x1080@60.00Hz, 0x0, 1";

    # # Version mismatch error
    # plugins = with inputs.hyprland-plugins.packages.${system}; [
    #   hyprtrails
    # ];

    settings = {
      "animations:enabled" = "0"; # disable window animations

      "$terminal" = "alacritty";

      "$mod" = "SUPER";

      # smaller gaps between windows and bg wallpaper
      "general:gaps_in" = "7";
      "general:gaps_out" = "7";

      bind = [
        "$mod, S, exec, rofi -show drun -show-icon"
        "ALT,Tab, cyclenext"
        "ALT_SHIFT,Tab,cyclenext,prev"

        "$mod, Return, exec, $terminal"
        "$mod, W, killactive,"
        "$mod CTRL, Q, exit,"
        "$mod, E, exec, $terminal -e $fileManager"
        "$mod, V, togglefloating,"
        "$mod, R, exec, $menu"
        "$mod, P, pseudo,"
        "$mod, J, togglesplit,"
        "$mod, F, fullscreen, 1"
        ", Print, exec, hyprshot -m region"
        "$mod, Print, exec, hyprshot -m output"

        "$mod, L, exec, hyprlock"

        # Move focus with mainMod + arrow keys
        "$mod, left, movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up, movefocus, u"
        "$mod, down, movefocus, d"

        # Switch workspaces with mainMod + [0-9]
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod, 6, workspace, 6"
        "$mod, 7, workspace, 7"
        "$mod, 8, workspace, 8"
        "$mod, 9, workspace, 9"
        "$mod, 0, workspace, 10"

        # Move active window to a workspace with mainMod + SHIFT + [0-9]
        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"
        "$mod SHIFT, 6, movetoworkspace, 6"
        "$mod SHIFT, 7, movetoworkspace, 7"
        "$mod SHIFT, 8, movetoworkspace, 8"
        "$mod SHIFT, 9, movetoworkspace, 9"
        "$mod SHIFT, 0, movetoworkspace, 10"

        # Scroll through existing workspaces with mainMod + scroll
        "$mod, mouse_down, workspace, e+1"
        "$mod, mouse_up, workspace, e-1"

        # TODO systemctl reboot --boot-loader-entry=auto-windows

        # Screenshots
        ", Print, exec, grim -g \"$(slurp)\" - | swappy -f - -o -" # save region
        "SHIFT, Print, exec, grim - | wl-copy && wl-paste > ~/Pictures/Screenshots/scrn-whole-$(date +%F_%T).png | dunstify 'Screenshot of whole screen taken' -t 1000" # save screen
      ];

      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      exec-once = [
        "${pkgs.swaylock}/bin/swaylock --image ${config.home.homeDirectory}/Pictures/bin.jpg --indicator-idle-visible"
        "hyprctl setcursor Bibata-Modern-Classic 24"
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
        "eDP-1,~/Pictures/bin.jpg"
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