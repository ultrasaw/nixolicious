{ config, pkgs, ... }:

{
  # Unfree packages
  nixpkgs.config.allowUnfree = true;
  
  programs.zsh.enable = true;
  users.defaultUserShell=pkgs.zsh;
  virtualisation.docker.enable = true;
  
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
    # (nerdfonts.override { fonts = [ "NerdFontsSymbolsOnly" ]; })
    nerd-fonts.symbols-only
    noto-fonts-emoji
  ];
}
