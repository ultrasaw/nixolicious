{ config, lib, pkgs, ... }:

let
  colors = (import ./colors.nix).catppuccin-macchiato;
in
{
  programs.swaylock = {
    enable = true;
    settings = with colors; {
      color = mantle;
      font-size = 48;
      font = "Cantarell";

      indicator-radius = 160;
      indicator-thickness = 20;

      ring-color = teal;
      inside-color = mantle;
      text-color = text;

      key-hl-color = green;
      bs-hl-color = maroon;

      ring-clear-color = peach;
      inside-clear-color = peach;
      text-clear-color = mantle;

      # "ver" is short for "Verifying"
      ring-ver-color = mauve;
      inside-ver-color = mauve;
      text-ver-color = mantle;

      ring-wrong-color = red;
      inside-wrong-color = red;
      text-wrong-color = mantle;

      line-color = crust;
      separator-color = crust;

      ignore-empty-password = true;
      indicator-idle-visible = false;
      show-failed-attempts = true;
    };
  };

  systemd = {
    user.services = {
      swaybg = {
        unitConfig = {
          Description = "swaybg service";
        };
        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.swaybg}/bin/swaybg -m fill -i ${config.home.homeDirectory}/Pictures/bin.jpg"; # Corrected ExecStart
          Restart = "on-failure";
        };
        installConfig = {
          WantedBy = [ "graphical-session.target" ];
        };
      };
    };
  };
}
