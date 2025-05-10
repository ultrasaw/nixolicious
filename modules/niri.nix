{ config, lib, pkgs, inputs, ... }:

{
  nixpkgs.overlays = [inputs.niri.overlays.niri];

  programs = {
    niri = {
      enable = true;
      # package = pkgs.niri-unstable;
    };
  };

  systemd.user.services.niri-flake-polkit.enable = false;

  services.gnome.sushi.enable = true;

  environment = {
    variables = {
      NIXOS_OZONE_WL = "1";
      __GL_GSYNC_ALLOWED = "0";
      __GL_VRR_ALLOWED = "0";
      DISABLE_QT5_COMPAT = "0";
      ANKI_WAYLAND = "1";
      DIRENV_LOG_FORMAT = "";
      WLR_DRM_NO_ATOMIC = "1";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      QT_QPA_PLATFORMTHEME = "qt5ct";
      QT_STYLE_OVERRIDE = "kvantum";
      MOZ_ENABLE_WAYLAND = "1";
      WLR_BACKEND = "vulkan";
      WLR_NO_HARDWARE_CURSORS = "1";
      XDG_SESSION_TYPE = "wayland";
      CLUTTER_BACKEND = "wayland";
      WLR_DRM_DEVICES = "/dev/dri/card1:/dev/dri/card0";
    };
    loginShellInit = ''
      eval $(ssh-agent)
      export GPG_TTY=$TTY
    '';
    systemPackages = with pkgs; [
      libsForQt5.qt5.qtwayland
      qt6.qtwayland
      playerctl
      swaynotificationcenter
      swayosd
      via # qmk
      xdg-utils
      angryipscanner

      telegram-desktop
      slack

      # blueman
      blueberry # bluetooth manager GUI
      networkmanager # network manager, including nmtui, a network manager TUI
      networkmanagerapplet # nm-applet --indicator &
      linssid

      seahorse # keyring manager GUI

      pwvucontrol # sound control
      playerctl # media player control

      inter # font
      bibata-cursors # Material Based Cursor Theme

      nautilus # file manager
      nautilus-python # further extend GNOME w/ python scripts; for nautilus-open-any-terminal
    ];
  };

  xdg.portal = {
    enable = true;
    # wlr.enable = true;
  };

  # xdg = {
  #   portal = {
  #     enable = true;
  #     xdgOpenUsePortal = true;
  #     config = {
  #       common.default = ["gtk"];
  #       hyprland.default = ["gtk" "hyprland"];
  #     };
  #     extraPortals = [
  #       pkgs.xdg-desktop-portal-gtk
  #     ];
  #   };
  # };
  
  security = {
    # allow wayland lockers to unlock the screen
    pam.services.swaylock.text = "auth include login";
  };

  # "open kitty here"
  programs.nautilus-open-any-terminal = {
    enable = true;
    terminal = "kitty";
  };

  services = {
    udev.packages = [ pkgs.via ]; # for qmk
    gnome.gnome-keyring.enable = true;
    # blueman.enable = true;
    # flatpak.enable = true; # to use Flatpak you must enable XDG Desktop Portals with xdg.portal.enable.
  };
}
