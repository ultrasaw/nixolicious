{ config, pkgs, ... }:

{
  # Unfree packages & Firefox
  nixpkgs.config.allowUnfree = true;
  programs.firefox.enable = true;

  # GnuPG
  services.pcscd.enable = true;
  programs.gnupg.agent = {
   enable = true;
   enableSSHSupport = true;
  };
}

