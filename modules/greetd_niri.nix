{ config, lib, pkgs, ... }:

let
  niriPackage = pkgs.niri;
  waybarPackage = pkgs.waybar-unstable;

  # This is the script greetd will run
  niriSessionScript = pkgs.writeShellScriptBin "niri-session-start" ''
    #!${pkgs.stdenv.shell}

    # start Niri in the background
    ${niriPackage}/bin/niri &
    NIRI_PID=$!
    sleep 2

    # start Waybar in the background
    systemctl --user start waybar.service &

    ${pkgs.swww}/bin/swww img ../assets/bin.png} &

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
