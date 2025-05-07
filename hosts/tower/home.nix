{ config, pkgs, inputs, theme, system, lib, ... }:

{
  colorScheme = inputs.nix-colors.colorSchemes."${theme}";

  imports = [
    # base
    ../../home/common.nix
    ../../home/vscode.nix
    ../../home/looks.nix
    ../../home/starship.nix

    # gnome
    ../../home/flameshot.nix

    # hyprland
    # ../../home/tiled.nix
    # ../../home/rofi.nix
    # ../../home/waybar.nix

    # niri
    # ../../home/niri.nix
    # ../../home/rofi.nix
    # ../../home/waybar.nix
    # ../../home/waybar_niri.nix
    # ../../home/swayidle.nix
    # ../../home/swaylock.nix
    # ../../home/xwayland-satellite.nix

    inputs.nix-colors.homeManagerModules.default
  ];
}
