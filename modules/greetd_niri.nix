{ config, lib, pkgs, ... }:

{
  services.greetd = {
    enable = true;
    settings = rec {
      initial_session = {
        command = "${pkgs.niri}/bin/niri";
        user = "gio";
      };
      default_session = initial_session;
    };
  };
}
