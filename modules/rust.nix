{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    rustc
    cargo
    libgccjit
    gcc
  ];
}
