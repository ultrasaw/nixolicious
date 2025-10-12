{ pkgs, config, lib, inputs, ... }:

let
  theme = config.lib.stylix.colors;
  windowSwitcher = pkgs.writeShellScriptBin "niri-window-switcher" ''
    # Get window information from niri
    windows_output=$(${config.programs.niri.package}/bin/niri msg windows)

    # Arrays to store window data
    declare -a window_ids
    declare -a window_titles
    declare -a window_apps
    declare -a focused_index

    # Parse the output
    current_id=""
    current_title=""
    current_app=""
    is_focused=false
    index=0

    while IFS= read -r line; do
        # Check if line starts with "Window ID"
        if [[ $line =~ ^Window\ ID\ ([0-9]+):(.*) ]]; then
            # Save previous window if exists
            if [[ -n "$current_id" ]]; then
                window_ids+=("$current_id")
                window_titles+=("$current_title")
                window_apps+=("$current_app")
                if $is_focused; then
                    focused_index=$index
                fi
                ((index++))
            fi
            
            # Start new window
            current_id="''${BASH_REMATCH[1]}"
            is_focused=false
            if [[ $line == *"(focused)"* ]]; then
                is_focused=true
            fi
            current_title=""
            current_app=""
        elif [[ $line =~ ^[[:space:]]*Title:\ \"(.*)\"$ ]]; then
            current_title="''${BASH_REMATCH[1]}"
        elif [[ $line =~ ^[[:space:]]*App\ ID:\ \"(.*)\"$ ]]; then
            current_app="''${BASH_REMATCH[1]}"
        fi
    done <<< "$windows_output"

    # Save last window
    if [[ -n "$current_id" ]]; then
        window_ids+=("$current_id")
        window_titles+=("$current_title")
        window_apps+=("$current_app")
        if $is_focused; then
            focused_index=$index
        fi
    fi

    # Build rofi list - focused window first, then others
    declare -a rofi_lines
    declare -a rofi_ids

    # Add focused window first
    if [[ -n "$focused_index" ]]; then
        rofi_lines+=("''${window_apps[$focused_index]}: ''${window_titles[$focused_index]}")
        rofi_ids+=("''${window_ids[$focused_index]}")
    fi

    # Add other windows
    for i in "''${!window_ids[@]}"; do
        if [[ $i -ne ''${focused_index:-999} ]]; then
            rofi_lines+=("''${window_apps[$i]}: ''${window_titles[$i]}")
            rofi_ids+=("''${window_ids[$i]}")
        fi
    done

    # Show in rofi and get selection
    if [[ ''${#rofi_lines[@]} -eq 0 ]]; then
        exit 0
    fi

    selected_index=$(printf '%s\n' "''${rofi_lines[@]}" | ${pkgs.rofi-wayland}/bin/rofi -dmenu -i -p "Windows" -format i -kb-accept-entry 'Alt_L,Return' -kb-row-up 'Up,Control-p,k' -kb-row-down 'Down,Control-n,j')

    # Focus the selected window
    if [[ -n "$selected_index" ]] && [[ "$selected_index" =~ ^[0-9]+$ ]]; then
        selected_id="''${rofi_ids[$selected_index]}"
        ${config.programs.niri.package}/bin/niri msg action focus-window --id "$selected_id"
    fi
  '';
in {

  # xdg.portal.extraPortals = [pkgs.xdg-desktop-portal-gtk pkgs.xdg-desktop-portal-gnome pkgs.gnome-keyring];
  xdg.portal.extraPortals = [pkgs.xdg-desktop-portal-gnome];
  home.packages = [pkgs.dconf pkgs.swww pkgs.brightnessctl pkgs.wl-clipboard windowSwitcher];
  programs.niri.settings = {
    binds = with config.lib.niri.actions; let
      sh = spawn "sh" "-c";
    in {
      "Mod+Shift+Slash".action = show-hotkey-overlay;

      "Alt+Tab".action = spawn "niri-window-switcher";

      "Mod+Return".action = spawn "kitty";
      "Mod+Space".action = sh "rofi -show drun -show-icon ";

      "Mod+Shift+S".action = screenshot;
      "Mod+S".action = sh "grim -g \"$(slurp)\" - | swappy -f - -o -";

      "Ctrl+Alt+Q".action = sh "swaylock -f -c 000000";
      "Mod+F".action = fullscreen-window;
      "Mod+M".action = maximize-column;
      "Mod+V".action = toggle-window-floating;

      "Mod+H".action = focus-column-left;
      "Mod+J".action = focus-window-or-workspace-down;
      "Mod+K".action = focus-window-or-workspace-up;
      "Mod+L".action = focus-column-right;

      "Mod+Shift+H".action = move-column-left;
      "Mod+Shift+J".action = move-window-down-or-to-workspace-down;
      "Mod+Shift+K".action = move-window-up-or-to-workspace-up;
      "Mod+Shift+L".action = move-column-right;

      "Mod+Left".action = focus-column-left;
      "Mod+Down".action = focus-window-or-workspace-down;
      "Mod+Up".action = focus-window-or-workspace-up;
      "Mod+Right".action = focus-column-right;

      "Mod+Shift+Left".action = move-column-left;
      "Mod+Shift+Down".action = move-window-down-or-to-workspace-down;
      "Mod+Shift+Up".action = move-window-up-or-to-workspace-up;
      "Mod+Shift+Right".action = move-column-right;

      "Ctrl+Alt+Right".action = consume-or-expel-window-right;
      "Ctrl+Alt+Left".action = consume-or-expel-window-left;
      "Ctrl+Alt+Return".action = move-window-to-monitor-next;

      "Ctrl+Alt+D".action = switch-preset-column-width;
      "Ctrl+Alt+A".action = switch-preset-window-height;
      "Ctrl+Alt+Tab".action = toggle-column-tabbed-display;

      "Mod+Minus".action = set-column-width "-10%";
      "Mod+Shift+Equal".action = set-column-width "+10%";

      "Mod+Ctrl+Minus".action = set-window-height "-10%";
      "Mod+Ctrl+Shift+Equal".action = set-window-height "+10%";

      # "Mod+S".action = screenshot;
      # "Mod+Shift+S".action = screenshot-screen;

      "Mod+WheelScrollDown" = {
        cooldown-ms = 150;
        action = focus-workspace-down;
      };

      "Mod+WheelScrollUp" = {
        cooldown-ms = 150;
        action = focus-workspace-up;
      };

      "Mod+Shift+WheelScrollDown".action = focus-column-right;
      "Mod+Shift+WheelScrollUp".action = focus-column-left;

      "Mod+Shift+C".action = close-window;
      "Mod+Ctrl+Shift+C".action = quit;

      "Mod+Comma".action = consume-window-into-column;
      "Mod+Period".action = expel-window-from-column;

      "XF86AudioRaiseVolume".action = sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1+";
      "XF86AudioLowerVolume".action = sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1-";
      "XF86AudioMute".action = sh "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";

      "XF86MonBrightnessUp".action = sh "brightnessctl set 5%+";
      "XF86MonBrightnessDown".action = sh "brightnessctl set 5%-";
      # "XF86Calculator".action = sh "${jpkgs.qalculate-gtk}/bin/qalculate-gtk";
      ######
      "Mod+1".action = focus-workspace 1;
      "Mod+2".action = focus-workspace 2;
      "Mod+3".action = focus-workspace 3;
      "Mod+4".action = focus-workspace 4;
      "Mod+5".action = focus-workspace 5;
      "Mod+6".action = focus-workspace 6;
      "Mod+7".action = focus-workspace 7;
      "Mod+8".action = focus-workspace 8;
      "Mod+9".action = focus-workspace 9;

      # "Mod+Shift+1".action = move-column-to-workspace 1;
      # "Mod+Shift+2".action = move-column-to-workspace 2;
      # "Mod+Shift+3".action = move-column-to-workspace 3;
      # "Mod+Shift+4".action = move-column-to-workspace 4;
      # "Mod+Shift+5".action = move-column-to-workspace 5;
      # "Mod+Shift+6".action = move-column-to-workspace 6;
      # "Mod+Shift+7".action = move-column-to-workspace 7;
      # "Mod+Shift+8".action = move-column-to-workspace 8;
      # "Mod+Shift+9".action = move-column-to-workspace 9;
    };

    environment = {
      DISPLAY = ":0"; # xwayland-satellite
    };

    # run 'niri msg outputs'
    outputs."DP-2" = {
      mode = {
        width = 3840;
        height = 2160;
        refresh = 120.000;
      };
    };

    outputs."DP-1" = {
      mode = {
        width = 3840;
        height = 2160;
        refresh = 120.000;
      };
    };

    outputs."HDMI-A-2" = {
      enable = false;
    };

    spawn-at-startup = [
      {
        command = ["ags"];
      }
      {
        command = ["swww-daemon"];
      }
      {
        command = ["dbus-update-activation-environment" "--all" "--systemd"];
      }
      {
        command = ["${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"];
      }
      {
        command = [
          "sh"
          "-c"
          ''
            eval $(gnome-keyring-daemon -s --components=pkcs11,secrets,ssh -f);
            export SSH_AUTH_SOCK;
          ''
        ];
      }
      {
        command = ["${pkgs.xwayland-satellite}/bin/xwayland-satellite"];
      }
    ];

    layout = {
      border = {
        active = {
          gradient = {
            angle = 130;
            relative-to = "workspace-view";
            from = "#${theme.base0D}";
            to = "#${theme.base0E}";
          };
        };
        inactive = {
          gradient = {
            angle = 130;
            relative-to = "workspace-view";
            from = "#${theme.base0D}90";
            to = "#${theme.base0E}90";
          };
        };
      };
    };

    input = {
      mouse.scroll-factor = 2.0;
      focus-follows-mouse.enable = false;
      touchpad.click-method = "clickfinger";
      
      # does not change the kb to beave like an apple one
      # keyboard = {
      #   xkb = {
      #     layout = "us(mac)";
      #     model = "applealu_ansi";
      #   };
      # };
    };

    animations = let
      movement-conf = {
        spring = {
          damping-ratio = 0.760000;
          epsilon = 0.000100;
          stiffness = 700;
        };
      };
    in {
      horizontal-view-movement = movement-conf;
      window-movement = movement-conf;
      workspace-switch = movement-conf;
    };

    window-rules = [
      # {
      #   matches = [
      #     {
      #       app-id = "^org.wezfurlong.wezterm$";
      #     }
      #   ];
      #   default-column-width = {};
      # }

      {
        geometry-corner-radius = {
          bottom-left = 12.0;
          bottom-right = 12.0;
          top-left = 12.0;
          top-right = 12.0;
        };
        clip-to-geometry = true;
      }
    ];

    gestures = {
      hot-corners.enable = false;
    };
  };
}
