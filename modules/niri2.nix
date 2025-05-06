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
    wlr.enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-wlr
      xdg-desktop-portal-gtk
    ];
  };

  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
    NIXOS_OZONE_WL = "1";
    NAUTILUS_4_EXTENSION_DIR = "${pkgs.nautilus-python}/lib/nautilus/extensions-4";
    SDL_VIDEODRIVER = "wayland";
    _JAVA_AWT_WM_NONREPARENTING = "1";
    QT_QPA_PLATFORM = "wayland";
    XDG_CURRENT_DESKTOP = "niri";
    XDG_SESSION_TYPE = "wayland";
    XDG_SESSION_DESKTOP = "niri";
  };

  # "open alacritty here"
  programs.nautilus-open-any-terminal = {
    enable = true;
    terminal = "alacritty";
  };

  # environment.pathsToLink = [ "/share/nautilus-python/extensions" ];
  
  environment.pathsToLink = [
    "/share/xdg-desktop-portal"
    "/share/applications"
    "/share/nautilus-python/extensions"
  ]; 

  environment.systemPackages = with pkgs; [
    playerctl
    swaynotificationcenter
    swayosd
    dbus
    xdg-utils

    blueman
    blueberry # bluetooth manager GUI
    networkmanager # network manager, including nmtui, a network manager TUI
    networkmanagerapplet # nm-applet --indicator &

    nautilus # file manager
    nautilus-python # further extend GNOME w/ python scripts; for nautilus-open-any-terminal
  ];

  services = {
    udev.packages = [ pkgs.via ]; # for qmk
    gnome.gnome-keyring.enable = true;
    blueman.enable = true;
    # flatpak.enable = true; # to use Flatpak you must enable XDG Desktop Portals with xdg.portal.enable.
  };
}
