{ config, pkgs, lib, ... }:

{

  wayland.windowManager.sway.systemd.enable = true;

  services.swayidle =
    let
      lock-timeout = 60 * minutes;
      sleep-timeout = 45 * minutes;

      seconds = 1;
      minutes = 60 * seconds;

      loginctl = "${pkgs.systemd}/bin/loginctl";
      systemctl = "${pkgs.systemd}/bin/systemctl";
      playerctl = "${pkgs.playerctl}/bin/playerctl";
      swaylock = "${pkgs.swaylock}/bin/swaylock";
      _1password = "${pkgs._1password-gui}/bin/1password";

      lock-session = pkgs.writeShellScript "lock-session" ''
        ${swaylock} -f -c 000000

        # # Run the 1password lock command only if 1password is running. If it is
        # # not running then the lock command will start it, which blocks this
        # # script, which prevents swayidle from working until 1password is
        # # closed.
        # if ! ps x | grep -v grep | grep 1password; then
        #   ${_1password} --lock
        # fi

        ${playerctl} pause 2>/dev/null || true
      '';

      before-sleep = pkgs.writeShellScript "before-sleep" ''
        ${loginctl} lock-session
      '';
    in
    {
      enable = true;
      timeouts = [
        { timeout = lock-timeout; command = "${loginctl} lock-session"; }
        # { timeout = sleep-timeout; command = "${systemctl} suspend"; }
      ];
      events = [
        { event = "lock"; command = lock-session.outPath; }
        { event = "before-sleep"; command = before-sleep.outPath; }
      ];
      systemdTarget = "niri.service";
    };

  # systemd.user.services.swayidle.Unit.After = "niri.service";

  # OSD for volume, brightness changes
  systemd.user.services.swayosd = {
    # Adjust swayosd restart policy - it's failing due to too many restart
    # attempts when resuming from sleep
    Unit.StartLimitIntervalSec = lib.mkForce 1;
  };
}
