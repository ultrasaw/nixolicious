{ config, pkgs, inputs, theme, system, ... }:

{
  imports = [
    ./hardware-configuration.nix
    inputs.home-manager.nixosModules.default
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 5;

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 1w";
  };

  # Hostname
  networking.hostName = "nixos";

  # Networking
  networking.networkmanager.enable = true;

  # Time and locale settings
  time.timeZone = "Europe/Vienna";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_AT.UTF-8";
    LC_IDENTIFICATION = "de_AT.UTF-8";
    LC_MEASUREMENT = "de_AT.UTF-8";
    LC_MONETARY = "de_AT.UTF-8";
    LC_NAME = "de_AT.UTF-8";
    LC_NUMERIC = "de_AT.UTF-8";
    LC_PAPER = "de_AT.UTF-8";
    LC_TELEPHONE = "de_AT.UTF-8";
    LC_TIME = "de_AT.UTF-8";
  };

  # Printing
  services.printing.enable = true;

  # QMK
  hardware.keyboard.qmk.enable = true;

  # Pipewire for audio
  hardware.pulseaudio.enable = false;
  hardware.bluetooth.enable = true;
  # services.blueman.enable = true;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # User account
  users.users.gio = {
    isNormalUser = true;
    # shell = pkgs.zsh; # defined in modules/base.nix; redundant, but kept for reference
    extraGroups = [ "networkmanager" "wheel" "docker" "kvm" ];
  };

  security.sudo.wheelNeedsPassword = false;

  home-manager = {
    extraSpecialArgs = {
      inherit inputs;
      inherit theme;
      inherit system;
      niriStable = inputs.niri-stable;
    };
    users = {
      "gio" = import ./home.nix;
    };
    sharedModules = [
      ./vars.nix
      ({ config, pkgs, ... }: { nixpkgs.config.allowUnfree = true; })
    ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  # System version
  system.stateVersion = "25.05";
}
