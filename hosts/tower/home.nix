{ config, pkgs, inputs, theme, ... }:

{
  colorScheme = inputs.nix-colors.colorSchemes."${theme}";

  imports = [
    ../../home/common.nix
    ../../home/tiled.nix
    ../../home/looks.nix
    ../../home/waybar.nix
    inputs.nix-colors.homeManagerModules.default
  ];
}
