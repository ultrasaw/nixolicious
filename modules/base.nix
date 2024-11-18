{ config, pkgs, ... }:

{
  # Unfree packages & chrome
  nixpkgs.config.allowUnfree = true;
  programs.zsh.enable = true;
  
  users.defaultUserShell=pkgs.zsh;

  # GnuPG
  services.pcscd.enable = true;
  programs.gnupg.agent = {
   enable = true;
   enableSSHSupport = true;
  };
}

