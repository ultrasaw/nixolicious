{ config, pkgs, ... }:

{
  services.xserver = {
    enable = true;
    layout = "us";
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
    xkb = { layout = "us"; variant = ""; };
  };

  programs.nautilus-open-any-terminal = {
    enable = true;
    terminal = "kitty";
  };

  environment.systemPackages = with pkgs; [
    via
    slack
    telegram-desktop
    gnomeExtensions.paperwm
    # vscode
    # eza
    # helix
  ];
}
