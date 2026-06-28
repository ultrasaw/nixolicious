{ pkgs, ... }:

{
  programs.steam = {
    enable = true;
    package = pkgs.steam.override {
      extraProfile = ''
        # Keep globally exported CUDA libraries from leaking into Steam's runtime.
        unset LD_LIBRARY_PATH

        steam_nvidia_cache_home="''${XDG_CACHE_HOME:-$HOME/.cache}/nvidia"
        mkdir -p "$steam_nvidia_cache_home/GLCache"
        export __GL_SHADER_DISK_CACHE=1
        export __GL_SHADER_DISK_CACHE_PATH="$steam_nvidia_cache_home/GLCache"
        export __GL_SHADER_DISK_CACHE_SIZE=10737418240
      '';
    };
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    gamescopeSession.enable = true;
    extraPackages = with pkgs; [
      gamescope
      mangohud
    ];
  };

  programs.gamemode.enable = true;

  environment.systemPackages = with pkgs; [
    protonup-qt
    mangohud
  ];
}
