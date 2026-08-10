{ pkgs, lib, ... }:

{
  services.tailscale = {
    enable = true;
    openFirewall = true;
    package = pkgs.unstable.tailscale;
  };

  services.openssh = {
    enable = true;
    openFirewall = false;
    settings = {
      AllowUsers = [ "gio" ];
      KbdInteractiveAuthentication = false;
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  users.users.gio.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAM2uodEiiEPwV05p+oAyyLYnaMi85VxASuTNvxBot9U neoserver@nixos"
  ];

  # SSH is reachable through the private tailnet, not the LAN or public NIC.
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 22 ];

  services.logind.settings.Login.HandlePowerKey = "ignore";

  systemd.services.opencode-web = {
    description = "OpenCode web interface";
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];

    environment = {
      HOME = "/home/gio";
      PATH = lib.mkForce "/etc/profiles/per-user/gio/bin:/home/gio/.nix-profile/bin:/run/current-system/sw/bin";
      XDG_CONFIG_HOME = "/home/gio/.config";
      XDG_DATA_HOME = "/home/gio/.local/share";
      XDG_STATE_HOME = "/home/gio/.local/state";
    };

    serviceConfig = {
      ExecStart = "${pkgs.unstable.opencode}/bin/opencode web --hostname 127.0.0.1 --port 4096";
      Group = "users";
      Restart = "on-failure";
      RestartSec = 5;
      UMask = "0077";
      User = "gio";
      WorkingDirectory = "/home/gio/Documents/_projects";
    };
  };
}
