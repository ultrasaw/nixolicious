{ config, lib, pkgs, ... }:

{
  programs.waybar = {

    enable = true;
    package = pkgs.unstable.waybar;
    systemd = {
      enable = true; # disable it, autostart it in hyprland conf
      target = "graphical-session.target";
    };
  };

  # programs.waybar = {
  #   enable = true;
  #   style = ''
  #     * {
  #       color: @text;
  #       font-family: JetBrainsMono Nerd Font;
  #       font-weight: bold;
  #       font-size: 14px;
  #     }

  #     window#waybar {
  #       background-color: rgba(0, 0, 0, 0);
  #     }

  #     #waybar > box {
  #       margin: 10px 15px 0px;
  #       background-color: @base;
  #       border: 2px solid @mauve;
  #     }

  #     #workspaces,
  #     #window,
  #     #idle_inhibitor,
  #     #wireplumber,
  #     #network,
  #     #cpu,
  #     #memory,
  #     #battery,
  #     #clock,
  #     #power-profiles-daemon,
  #     #tray,
  #     #waybar > box {
  #       border-radius: 12px;
  #     }

  #     #workspaces * {
  #       color: @red;
  #     }

  #     #idle_inhibitor {
  #       color: @peach;
  #     }

  #     #window * {
  #       color: @mauve;
  #     }

  #     #wireplumber {
  #       color: @yellow;
  #     }

  #     #network {
  #       color: @green;
  #     }

  #     #power-profiles-daemon {
  #       color: @teal;
  #     }

  #     #battery {
  #       color: @blue;
  #     }

  #     #clock {
  #       color: @lavender;
  #     }

  #     #tray {
  #       color: @text;
  #     }

  #     #idle_inhibitor,
  #     #wireplumber,
  #     #network,
  #     #cpu,
  #     #memory,
  #     #battery,
  #     #clock,
  #     #power-profiles-daemon,
  #     #tray {
  #       padding: 0 5px;
  #     }
  #   '';

  #   settings = {
  #     mainBar = {
  #       layer = "top";
  #       position = "top";
  #       spacing = 4;
  #       modules-left = [
  #         "hyprland/workspaces"
  #         "hyprland/window"
  #       ];
  #       modules-center = [
  #       ];
  #       modules-right = [
  #         "idle_inhibitor"
  #         "wireplumber"
  #         "network"
  #         "power-profiles-daemon"
  #         "battery"
  #         "clock"
  #         "tray"
  #       ];

  #       "hyprland/workspaces" = {
  #         disable-scroll = true;
  #         all-outputs = true;
  #         warp-on-scroll = false;
  #         format = "{name}: {icon}";
  #         format-icons = {
  #           "urgent" = "";
  #           "active" = "";
  #           "default" = "";
  #         };
  #       };

  #       #cava = {
  #       #  cava_config = "$HOME/.config/cava/config";
  #       #  framerate = 60;
  #       #  bars = 16;
  #       #  method = "pipewire";
  #       #  format-icons = ["▁" "▂" "▃" "▄" "▅" "▆" "▇" "█" ];
  #       #  bar_delimiter = 0;
  #       #};

  #       idle_inhibitor = {
  #         format = "Idle: {icon} ";
  #         format-icons = {
  #           "deactivated" = "";
  #           "activated" = "";
  #         };
  #       };

  #       wireplumber = {
  #         format = "Volume: {icon}  {volume}% ";
  #         format-icons = ["" "" ""];
  #         format-muted = "Muted ";
  #       };

  #       clock = {
  #         format = "  {:%H:%M}";
  #       };

  #       network = {
  #         format = "  {essid} 󰓅 {signalStrength}";
  #       };

  #       power-profiles-daemon = {
  #         format = "Profile: {icon} ";
  #         tooltip-format = "Power profile: {profile}\nDriver: {driver}";
  #         tooltip = true;
  #         format-icons = {
  #           default = "";
  #           performance = "";
  #           balanced = "";
  #           power-saver = "";
  #         };
  #       };

  #       battery = {
  #         format-icons = ["" "" "" "" ""];
  #         format = "{icon}  {capacity}%";
  #       };
  #     };
  #   };
  # };
}
