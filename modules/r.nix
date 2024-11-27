{ config, pkgs, ... }:

let
  rPackages = with pkgs.rPackages; [
    dplyr
    ggplot2
    plotly
    DT
    tidyr
    # remotes # for e.g. catboost
    xgboost
  ];

  r = pkgs.rWrapper.override {
    packages = rPackages;
  };

  rstudio = pkgs.rstudioWrapper.override {
    packages = rPackages;
  };
in
{
  environment.systemPackages = with pkgs; [
    r
    rstudio
  ];
}
