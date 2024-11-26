{ config, pkgs, ... }:

let
  shared = with pkgs.rPackages; [
    dplyr
    ggplot2
    plotly
    DT
    tidyr
    # remotes # for e.g. catboost
    xgboost
  ];

  r = pkgs.rWrapper.override {
    packages = shared;
  };

  rstudio = pkgs.rstudioWrapper.override {
    packages = shared;
  };
in
{
  environment.systemPackages = with pkgs; [
    r
    rstudio
  ];
}
