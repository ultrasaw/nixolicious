{ config, lib, pkgs, ... }:

let
  niriPackage = pkgs.niri;
  waybarPackage = pkgs.unstable.waybar;

  # This is the script greetd will run
  niriSessionScript = pkgs.writeShellScriptBin "niri-session-start" ''
    #!${pkgs.stdenv.shell}

    # Initialize PAM's keyring before the first screen unlock. Share its
    # control socket with Niri, swaylock, and D-Bus-activated applications.
    export GNOME_KEYRING_CONTROL="''${XDG_RUNTIME_DIR:?}/keyring"
    ${pkgs.gnome-keyring}/bin/gnome-keyring-daemon \
      --start --components=pkcs11,secrets \
      --control-directory "$GNOME_KEYRING_CONTROL" >/dev/null || exit 1

    # start Niri in the background
    ${niriPackage}/bin/niri &
    NIRI_PID=$!
    sleep 3

    # start Waybar in the background
    systemctl --user start waybar.service &

    # wallpaper
    # Manual fallback after upgrades: awww img /home/gio/Documents/_projects/nixolicious/assets/000011580013.JPG
    ${pkgs.awww}/bin/awww img /home/gio/Documents/_projects/nixolicious/assets/000011580013.JPG &

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
