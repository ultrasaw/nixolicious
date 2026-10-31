{ config, pkgs, ... }:

{
  # Unfree packages
  nixpkgs.config.allowUnfree = true;
  
  programs.zsh.enable = true;
  users.defaultUserShell=pkgs.zsh;
  virtualisation.docker.enable = true;

  boot.binfmt = {
    emulatedSystems = [ "aarch64-linux" ];
    preferStaticEmulators = true;
  };
  
  # GnuPG
  services.pcscd.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    # Use the login keyring without the GNOME/GCR pinentry dialog.
    # External caching stays enabled by default for keyring retrieval.
    pinentryPackage = pkgs.pinentry-qt;
    settings = {
      # Effectively cache until reboot (68 years); agent restarts also clear it.
      default-cache-ttl = 2147483647;
      max-cache-ttl = 2147483647;
      pinentry-timeout = 120;
      allow-loopback-pinentry = "";
    };
  };

  fonts.packages = with pkgs; [
    font-awesome
    powerline-fonts
    powerline-symbols
    # (nerdfonts.override { fonts = [ "NerdFontsSymbolsOnly" ]; })
    nerd-fonts.symbols-only
    noto-fonts-color-emoji
  ];
}
