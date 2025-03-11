{ config, pkgs, ... }:
{
  environment.etc = let
    conn = (pkgs.formats.ini { }).generate "NDC2.nmconnection" {
      connection = {
        id = "NDC2";
        uuid = "9f39a22d-d644-470a-bcc8-b4585478fd41";
        type = "vpn";
      };

      vpn = {
        auth = "SHA256";
        ca = builtins.toString /home/gio/Documents/NDC2/ca.pem;
        cert = builtins.toString /home/gio/Documents/NDC2/cert.pem;
        "challenge-response-flags" = 2;
        compress = "lz4";
        "connection-type" = "tls";
        "data-ciphers" = "AES-128-GCM:AES-128-CBC";
        dev = "tun";
        key = builtins.toString /home/gio/Documents/NDC2/key.pem;
        remote = "84.242.8.194:1194:tcp4";
        "remote-cert-tls" = "server";
        ta = builtins.toString /home/gio/Documents/NDC2/tls-auth.pem;
        "ta-dir" = 1;
        "verify-x509-name" = "name:firewall01.local";
        "service-type" = "org.freedesktop.NetworkManager.openvpn";
      };

      ipv4 = {
        method = "auto";
      };

      ipv6 = {
        "addr-gen-mode" = "default";
        method = "auto";
      };

      proxy = { };
    };
  in
  {
    "NetworkManager/system-connections/${conn.name}" = {
      source = conn;
      mode = "0600";
    };
  };
}
