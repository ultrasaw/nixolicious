{ config, lib, pkgs, ... }:

let
  colors = (import ./colors.nix).catppuccin-macchiato;
in
{

  programs = {
    niri = {
      enable = true;
      package = pkgs.niri;
    };

    dconf.enable = true;
    xwayland.enable = true;
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-gnome
    ];
  };

  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
    NIXOS_OZONE_WL = "1";
    NAUTILUS_4_EXTENSION_DIR = "${pkgs.nautilus-python}/lib/nautilus/extensions-4";
    SDL_VIDEODRIVER = "wayland";
    _JAVA_AWT_WM_NONREPARENTING = "1";
    QT_QPA_PLATFORM = "wayland";
    # XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_TYPE = "wayland";
    # XDG_SESSION_DESKTOP = "Hyprland";
  };

  environment.systemPackages = with pkgs; [
    playerctl
    swaynotificationcenter
    swayosd
    dbus

    blueman
    blueberry # bluetooth manager GUI
    networkmanager # network manager, including nmtui, a network manager TUI
    networkmanagerapplet # nm-applet --indicator &
  ];

  services = {
    udev.packages = [ pkgs.via ]; # for qmk
    gnome.gnome-keyring.enable = true;
    blueman.enable = true;
    # flatpak.enable = true; # to use Flatpak you must enable XDG Desktop Portals with xdg.portal.enable.
  };
}
