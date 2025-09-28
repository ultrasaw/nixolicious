{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    unstable.rustc
    unstable.cargo
    unstable.gcc
    unstable.pkg-config
  ];
}
