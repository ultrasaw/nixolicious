{ config, pkgs, ... }:

{
  home.packages = [ pkgs.swaynotificationcenter ];

  systemd.user.services.swaync = {
    Unit = {
      Description = "SwayNotificationCenter";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.swaynotificationcenter}/bin/swaync -c ${config.xdg.configHome}/swaync/config.json -s ${config.xdg.configHome}/swaync/style.css";
      Restart = "on-failure";
      Environment = [
        "GSK_RENDERER=gl"
        "XDG_CONFIG_HOME=${config.xdg.cacheHome}/swaync-xdg"
      ];
    };
    Install.WantedBy = [ "niri.service" ];
  };
}
