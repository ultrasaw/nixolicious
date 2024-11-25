{ config, pkgs, inputs, ... }:

{
  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages."${pkgs.system}".hyprland;
    xwayland.enable = true;
  };

  security = {
    # Gnome keyring
    polkit.enable = true;
    # swaylock
    # https://discourse.nixos.org/t/swaylock-wont-unlock/27275
    pam.services.swaylock.fprintAuth = false;
  };

  services = {
    udev.packages = [ pkgs.via ]; # for qmk

    gnome.gnome-keyring.enable = true;

    flatpak.enable = true;

    # Bluetooth
    blueman.enable = true;
  };

  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
    NIXOS_OZONE_WL = "1";
    NAUTILUS_4_EXTENSION_DIR = "${pkgs.gnome.nautilus-python}/lib/nautilus/extensions-4";
  };

  # "open alacritty here"
  programs.nautilus-open-any-terminal = {
    enable = true;
    terminal = "alacritty";
  };

  environment.pathsToLink = [ "/share/nautilus-python/extensions" ];

  environment.systemPackages = with pkgs; [
    via # for qmk

    dunst
    libnotify

    swaylock # screen locker
    xdg-utils # allow xdg-open to work

    hyprpicker # color pickere

    # waybar applets
    networkmanagerapplet # nm-applet --indicator &
    blueman # blueman-applet
    udiskie # removable media/disk mounting

    polkit_gnome # polkit agent for GNOME
    gnome.seahorse # keyring manager GUI
    gnome.nautilus # file manager
    gnome.nautilus-python # further extend GNOME w/ python scripts; for nautilus-open-any-terminal

    playerctl # media player control
    brightnessctl # brightness control
    pwvucontrol # sound control

    blueberry # bluetooth manager GUI
    networkmanager # network manager, including nmtui, a network manager TUI

    inter # font
    bibata-cursors # Material Based Cursor Theme

    spotify
    linssid
    angryipscanner

    inputs.hyprland-contrib.packages.${pkgs.system}.grimblast

  ];

  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

  # hardware = {
  #   opengl.enable = true;
  # };

}
