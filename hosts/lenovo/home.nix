{ config, pkgs, inputs, theme, system, ... }:

{
  colorScheme = inputs.nix-colors.colorSchemes."${theme}";

  imports = [
    ../../home/common.nix
    ../../home/vscode.nix
    # ../../home/tiled_lenovo.nix
    ../../home/looks.nix
    ../../home/waybar.nix
    ../../home/rofi.nix
    ../../home/starship.nix
    inputs.nix-colors.homeManagerModules.default
  ];
}
