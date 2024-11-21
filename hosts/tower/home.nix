{ config, pkgs, ... }:

{
  imports = [
    ../../home/common.nix
    ../../home/tiled.nix
    ../../home/looks.nix
    ../../home/waybar.nix
  ];
}
