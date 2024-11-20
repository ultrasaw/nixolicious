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
    gnome.gnome-keyring.enable = true;

    flatpak.enable = true;

    # Bluetooth
    blueman.enable = true;
  };

  # programs.sway = {
  #   enable = true;
  #   extraPackages = with pkgs; [swaylock-effects];
  # };

  # services.xserver = {
  #   enable = true;
  #   layout = "us";
  #   displayManager.gdm.enable = true;
  #   displayManager.defaultSession = "hyprland";
  #   xkb = { layout = "us"; variant = ""; };
  # };

  # services.greetd = {
  #   enable = true;
  #   settings = rec {
  #     initial_session = {
  #       command = "${pkgs.hyprland}/bin/Hyprland";
  #       user = "gio";
  #     };
  #     default_session = initial_session;
  #   };
  # };

  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
    NIXOS_OZONE_WL = "1";
  };

  environment.systemPackages = with pkgs; [

    kitty

    grim
    slurp
    wl-clipboard

    dunst
    libnotify

    rofi-wayland

    swww

    waybar
    (waybar.overrideAttrs (oldAttrs: {
        mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true" ];
      })
    )

    swaylock # screen locker
    gnome.nautilus # file manager
    xdg-utils # allow xdg-open to work

  ];

  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

  # hardware = {
  #   opengl.enable = true;
  # };

}
