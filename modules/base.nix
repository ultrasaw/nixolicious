{ config, pkgs, ... }:

{
  # Unfree packages
  nixpkgs.config.allowUnfree = true;
  
  programs.zsh.enable = true;
  virtualisation.docker.enable = true;
  
  users.defaultUserShell=pkgs.zsh;

  # GnuPG
  services.pcscd.enable = true;
  programs.gnupg.agent = {
   enable = true;
   enableSSHSupport = true;
  };

  fonts.packages = with pkgs; [
    font-awesome
    powerline-fonts
    powerline-symbols
    (nerdfonts.override { fonts = [ "NerdFontsSymbolsOnly" ]; })
  ];
}
