{ config, lib, pkgs, ... }:

let
  niriPackage = pkgs.niri;
  waybarPackage = pkgs.unstable.waybar;

  # This is the script greetd will run
  niriSessionScript = pkgs.writeShellScriptBin "niri-session-start" ''
    #!${pkgs.stdenv.shell}

    # start Niri in the background
    ${niriPackage}/bin/niri &
    NIRI_PID=$!
    sleep 3

    # start Waybar in the background
    systemctl --user start waybar.service &

    # wallpaper
    ${pkgs.swww}/bin/swww img ../assets/000011580013.JPG} &

    # idle locking
    systemctl --user start swayidle.service &

    # add every private key in ~/.ssh (skip .pub files)
    for k in ~/.ssh/*; do
      case $k in
        *.pub|*config) continue ;;
      esac
      ssh-add "$k" 2>/dev/null
    done &

    # when Niri exits, the wait will end,
    # the script will exit, and greetd will end the session.
    wait $NIRI_PID
  '';
in {
  services.greetd = {
    enable = true;
    settings = rec {
      initial_session = {
        # Point greetd to your new script
        command = "${niriSessionScript}/bin/niri-session-start";
        user = "gio"; # Ensure this is your correct username
      };
      default_session = initial_session;
    };
  };
}
