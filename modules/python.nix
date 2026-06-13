{ config, pkgs, ... }:

let
  python-with-packages = pkgs.python3.withPackages (ps: with ps; [
    jq # example system-wide packages
    yq
    numpy
    polars
  ]);
in
{
  environment.systemPackages = with pkgs; [
    pyright
    black
    isort

    # py pkgs
    python-with-packages
  ];
}
