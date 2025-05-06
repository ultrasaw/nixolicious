{ config, pkgs, inputs, theme, system, lib, ... }:

{
  colorScheme = inputs.nix-colors.colorSchemes."${theme}";

  imports = [
    ../../home/common.nix
    ../../home/vscode.nix
    # ../../home/tiled.nix
    ../../home/looks.nix
    ../../home/waybar_niri.nix
    ../../home/xwayland-satellite.nix
    ../../home/rofi.nix
    ../../home/starship.nix
    ../../home/flameshot.nix
    ../../home/swayidle.nix
    ../../home/swaylock.nix
    inputs.nix-colors.homeManagerModules.default
  ];
}
