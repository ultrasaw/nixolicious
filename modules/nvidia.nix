{ lib, pkgs, config, ...}:

let
  nvidiaDriverChannel = config.boot.kernelPackages.nvidiaPackages.stable; # stable, beta, latest, etc.

  # Prebuilt ollama with bundled CUDA libs -- works around nixpkgs CUDA toolkit
  # compilation bugs (nixpkgs#389661, nixpkgs#458056) where ptxas/cicc segfault.
  ollama-prebuilt = pkgs.stdenv.mkDerivation rec {
    pname = "ollama";
    version = "0.18.0";

    src = pkgs.fetchzip {
      url = "https://github.com/ollama/ollama/releases/download/v${version}/ollama-linux-amd64.tar.zst";
      hash = "sha256-Ml4Gt4hZXTrIE+DR+5Mo6ZKCQDR1Mi4JOjmYVJFFcsQ=";
      stripRoot = false;
      nativeBuildInputs = [ pkgs.zstd ];
    };

    nativeBuildInputs = [ pkgs.autoPatchelfHook pkgs.makeWrapper ];
    buildInputs = [ pkgs.stdenv.cc.cc.lib pkgs.zlib ];

    autoPatchelfIgnoreMissingDeps = [ "libcuda.so.1" ];

    dontBuild = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r bin $out/
      cp -r lib $out/
      runHook postInstall
    '';

    postFixup = ''
      wrapProgram $out/bin/ollama \
        --prefix LD_LIBRARY_PATH : "/run/opengl-driver/lib"
    '';

    meta.mainProgram = "ollama";
  };
in {
  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = ["nvidia"]; # or "nvidiaLegacy470 etc.
  boot.kernelParams = lib.optionals (lib.elem "nvidia" config.services.xserver.videoDrivers) [
    "nvidia-drm.modeset=1"
    "nvidia_drm.fbdev=1"
  ];
  
  environment.variables = {
    GBM_BACKEND = "nvidia-drm";
    WLR_NO_HARDWARE_CURSORS = "1";
    LIBVA_DRIVER_NAME = "nvidia";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    # Applications provide their CUDA libraries; only expose the driver globally.
    LD_LIBRARY_PATH = "/run/opengl-driver/lib";
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
      powerManagement.enable = true;
      modesetting.enable = true;
      package = nvidiaDriverChannel;
    };
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        nvidia-vaapi-driver
        libva-vdpau-driver
        libvdpau-va-gl
        # CUDA toolkits are not graphics drivers and do not belong here.
      ];
    };
  };
  
  # Keep compiler/runtime tools without pulling in the full CUDA toolkit
  # (including the large cuBLAS static libraries). Ollama bundles its own libs.
  environment.systemPackages = with pkgs; [
    cudaPackages.cuda_nvcc
    cudaPackages.cuda_cudart
  ];

  services.ollama = {
    enable = true;
    package = ollama-prebuilt;
  };
}
