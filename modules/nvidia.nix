{ lib, pkgs, config, ...}:

let
  nvidiaDriverChannel = config.boot.kernelPackages.nvidiaPackages.stable; # stable, beta, latest, etc.
in {
  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = ["nvidia"]; # or "nvidiaLegacy470 etc.
  boot.kernelParams = lib.optionals (lib.elem "nvidia" config.services.xserver.videoDrivers) [
    "nvidia-drm.modeset=1"
    "nvidia_drm.fbdev=1"
  ];
  
  environment.variables = {
    CUDA_PATH = "${pkgs.cudaPackages.cudatoolkit}";
    CUDA_ROOT = "${pkgs.cudaPackages.cudatoolkit}";
    GBM_BACKEND = "nvidia-drm";
    WLR_NO_HARDWARE_CURSORS = "1";
    LIBVA_DRIVER_NAME = "nvidia";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    # Ensure CUDA libraries are in the path
    LD_LIBRARY_PATH = "/run/opengl-driver/lib:${pkgs.cudaPackages.cudatoolkit}/lib";
  };
  
  nixpkgs.config = {
    nvidia.acceptLicense = true;
    allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
      "cudatoolkit"
      "cuda_cudart"
      "cuda_cccl"
      "cuda_nvcc"
      "libcublas"
      "libcufft"
      "libcurand"
      "libcusolver"
      "libcusparse"
      "libnpp"
      "nvidia-persistenced"
      "nvidia-settings"
      "nvidia-x11"
    ];
  };
  
  hardware = {
    nvidia = {
      open = false;
      nvidiaSettings = true;  # Changed to true for debugging
      powerManagement.enable = false;
      modesetting.enable = true;
      package = nvidiaDriverChannel;
    };
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        nvidia-vaapi-driver
        vaapiVdpau
        libvdpau-va-gl
        # Add CUDA packages to system graphics packages
        cudaPackages.cudatoolkit
        cudaPackages.cuda_cudart
      ];
    };
  };
  
  # Optional: Add CUDA packages to system packages for global access
  environment.systemPackages = with pkgs; [
    cudaPackages.cudatoolkit
    cudaPackages.cuda_nvcc
    cudaPackages.cuda_cudart
  ];
}
