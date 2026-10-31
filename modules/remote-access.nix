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

  # Private phone preview: reconnect only the dev HTTP forward, never production. (c) opencode
  systemd.services.tot-dev-preview = {
    description = "Private tot-dev application forward";
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    environment.KUBECONFIG = "/home/gio/.cache/kubeconfig/config";
    serviceConfig = {
      User = "gio";
      Group = "users";
      ExecStart = "${pkgs.unstable.kubectl}/bin/kubectl --context tot-prod-k3s --namespace tot-dev port-forward --address=127.0.0.1 service/tot-server 18080:8080";
      Restart = "always";
      RestartSec = 5;
      UMask = "0077";
      NoNewPrivileges = true;
    };
    startLimitIntervalSec = 0;
  };

  # Configure only this private listener; preserve OpenCode on 443. No Funnel. (c) opencode
  systemd.services.tot-dev-preview-serve = {
    description = "Private Tailscale HTTPS endpoint for tot-dev";
    wantedBy = [ "multi-user.target" ];
    wants = [ "tailscaled.service" "tot-dev-preview.service" ];
    after = [ "tailscaled.service" "tot-dev-preview.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.unstable.tailscale}/bin/tailscale serve --bg --https=8443 http://127.0.0.1:18080";
      Restart = "on-failure";
      RestartSec = 5;
    };
    startLimitIntervalSec = 0;
  };

  systemd.services.opencode-web = {
    description = "OpenCode web interface";
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];

    environment = {
      HOME = "/home/gio";
      # System services do not inherit home.sessionVariables; use the same
      # session database as the terminal client in home/common.nix.
      OPENCODE_DB = "opencode-stable.db";
      PATH = lib.mkForce "/etc/profiles/per-user/gio/bin:/home/gio/.nix-profile/bin:/run/current-system/sw/bin";
      XDG_CONFIG_HOME = "/home/gio/.config";
      XDG_DATA_HOME = "/home/gio/.local/share";
      XDG_STATE_HOME = "/home/gio/.local/state";
    };

    serviceConfig = {
      ExecStart = "${pkgs.unstable.opencode}/bin/opencode serve --hostname 127.0.0.1 --port 4096";
      Group = "users";
      Restart = "on-failure";
      RestartSec = 5;
      UMask = "0077";
      User = "gio";
      WorkingDirectory = "/home/gio/Documents/_projects";
    };
  };
}
