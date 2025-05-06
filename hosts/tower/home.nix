{ config, pkgs, inputs, theme, system, lib, ... }:

{
  colorScheme = inputs.nix-colors.colorSchemes."${theme}";

  imports = [
    ../../home/common.nix
    ../../home/vscode.nix
    # ../../home/tiled.nix
    ../../home/looks.nix
    # ../../home/rofi.nix
    ../../home/starship.nix
    ../../home/flameshot.nix
    # ../../home/waybar_niri.nix
    # ../../home/swayidle.nix
    # ../../home/swaylock.nix
    # ../../home/xwayland-satellite.nix
    inputs.nix-colors.homeManagerModules.default
  ];
}
