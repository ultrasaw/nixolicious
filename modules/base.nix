{ config, pkgs, ... }:

{
  # Unfree packages
  nixpkgs.config.allowUnfree = true;
  
  programs.zsh.enable = true;
  users.defaultUserShell=pkgs.zsh;
  virtualisation.docker.enable = true;

  environment.variables = {
    GODEBUG = "tlsmlkem=0";
    OPENSSL_CONF = "/etc/ssl/openssl-no-hybrid.cnf";
  };

  environment.etc."ssl/openssl-no-hybrid.cnf".text = ''
    openssl_conf = openssl_init

    [openssl_init]
    ssl_conf = ssl_sect

    [ssl_sect]
    system_default = system_default_sect

    [system_default_sect]
    Groups = X25519:P-256:P-384:P-521
  '';

  security.sudo.extraConfig = ''
    Defaults env_keep += "GODEBUG OPENSSL_CONF"
  '';

  systemd.services.nix-daemon.environment = {
    OPENSSL_CONF = "/etc/ssl/openssl-no-hybrid.cnf";
  };

  boot.binfmt = {
    emulatedSystems = [ "aarch64-linux" ];
    preferStaticEmulators = true;
  };
  
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
    noto-fonts-color-emoji
  ];
}
