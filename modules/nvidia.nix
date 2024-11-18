{ config, pkgs, ... }:

{
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    # package = pkgs.linuxKernel.packages.linux_6_6.nvidia_x11;
    prime = { 
      intelBusId = "PCI:00:02.0";
      nvidiaBusId = "PCI:01:00.0";
    };
  };
}
