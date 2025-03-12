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
    NAUTILUS_4_EXTENSION_DIR = "${pkgs.nautilus-python}/lib/nautilus/extensions-4";
    SDL_VIDEODRIVER = "wayland";
    _JAVA_AWT_WM_NONREPARENTING = "1";
    QT_QPA_PLATFORM = "wayland";
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_TYPE = "wayland";
    XDG_SESSION_DESKTOP = "Hyprland";
  };

  # "open alacritty here"
  programs.nautilus-open-any-terminal = {
    enable = true;
    terminal = "alacritty";
  };

  environment.pathsToLink = [ "/share/nautilus-python/extensions" ];

  environment.systemPackages = with pkgs; [
    via # for qmk

    slack
    telegram-desktop

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
    seahorse # keyring manager GUI
    nautilus # file manager
    nautilus-python # further extend GNOME w/ python scripts; for nautilus-open-any-terminal

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

  # xdg.portal.enable = true;
  # xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

 xdg = {
   portal = {
     enable = true;
     xdgOpenUsePortal = true;
     config = {
       common.default = ["gtk"];
       hyprland.default = ["gtk" "hyprland"];
     };
     extraPortals = [
       pkgs.xdg-desktop-portal-gtk
     ];
   };
 };

  # hardware = {
  #   opengl.enable = true;
  # };

}
