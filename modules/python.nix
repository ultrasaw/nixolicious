{ config, pkgs, ... }:

let
  pythonPackages = with pkgs.python3Packages; [
    numpy
    pandas
    matplotlib
    plotly
    scikit-learn
    catboost
    yq
    jq
  ];

  pythonEnv = pkgs.python3.withPackages (ps: pythonPackages);
in
{
  environment.systemPackages = with pkgs; [
    pythonEnv
  ];
}
