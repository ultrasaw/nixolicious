{ config, pkgs, ... }:

{
  services.xserver = {
    enable = true;
    layout = "us";
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
    xkb = { layout = "us"; variant = ""; };
  };

  environment.systemPackages = with pkgs; [
  via # for qmk

  slack
  telegram-desktop

  ];
}
