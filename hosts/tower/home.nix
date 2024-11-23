{ config, pkgs, inputs, theme, system, ... }:

{
  colorScheme = inputs.nix-colors.colorSchemes."${theme}";

  imports = [
    ../../home/common.nix
    ../../home/tiled.nix
    ../../home/looks.nix
    ../../home/waybar.nix
    ../../home/rofi.nix
    inputs.nix-colors.homeManagerModules.default
  ];

  # packages = [
  #   (import ../../scripts/rofi-launcher.nix { inherit pkgs; })
  # ];

}
