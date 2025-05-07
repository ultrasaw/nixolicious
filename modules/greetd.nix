{ config, lib, pkgs, ... }:

{
  services.greetd = {
    enable = true;
    settings = rec {
      initial_session = {
        command = "${pkgs.niri}/bin/niri";
        user = "gio";
      };
      default_session = initial_session;
    };
  };
}  

# let
#   greetConfig = pkgs.writeText "greetd-sway-config" ''
#     # `-l` activates layer-shell mode. Notice that `swaymsg exit` will run after gtkgreet.
#     exec "${pkgs.greetd.gtkgreet}/bin/gtkgreet -l; swaymsg exit"
#     bindsym Mod4+shift+e exec swaynag \
#       -t warning \
#       -m 'What do you want to do?' \
#       -b 'Poweroff' 'systemctl poweroff' \
#       -b 'Reboot' 'systemctl reboot'
#   '';
# in
# {
#   services.greetd = {
#     enable = true;
#     settings = {
#       default_session = {
#         command = "${pkgs.hyprland}/bin/Hyprland --config ${greetConfig}";
#       };
#     };
#   };

#   # environment.etc."greetd/environments".text = ''
#   #   sway
#   #   fish
#   #   bash
#   #   startxfce4
#   # '';
# }
