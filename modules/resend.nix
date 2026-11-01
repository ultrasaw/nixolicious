# Resend is updated outside the Nix store on activation, not during a build.
# This deliberately follows npm's latest release rather than flake.lock.
{ pkgs, ... }:

let
  nodejs = pkgs.unstable.nodejs;
  updater = pkgs.writeShellApplication {
    name = "resend-update";
    runtimeInputs = [ nodejs pkgs.coreutils pkgs.jq pkgs.util-linux ];
    text = ''
      export npm_config_cafile=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
    '' + builtins.readFile ./resend-update.sh;
  };
  resend = pkgs.writeShellScriptBin "resend" ''
    cli="$HOME/.local/share/resend-cli/current/lib/node_modules/resend-cli/dist/cli.cjs"
    if [ ! -f "$cli" ]; then
      echo "resend: not installed yet; run resend-update and try again." >&2
      exit 1
    fi
    exec ${nodejs}/bin/node "$cli" "$@"
  '';
in
{
  environment.systemPackages = [ resend updater ];

  # Unlike a service restart trigger, this runs even on an unchanged switch.
  # Activation also runs at boot, when networking may not yet be available.
  # Never run downloaded npm code as root or prevent activation when offline.
  system.activationScripts.resend = {
    deps = [ "users" ];
    text = ''
      if ! ${pkgs.util-linux}/bin/runuser -u gio -- ${updater}/bin/resend-update; then
        echo "resend: update failed; keeping any previous installation. Retry with resend-update." >&2
      fi
    '';
  };
}
