{ pkgs, ... }:

{
  home.packages = [ pkgs.swaynotificationcenter ];

  systemd.user.services.swaync = {
    Unit = {
      Description = "SwayNotificationCenter";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.swaynotificationcenter}/bin/swaync";
      Restart = "on-failure";
      Environment = [ "GSK_RENDERER=gl" ];
    };
    Install.WantedBy = [ "niri.service" ];
  };
}
