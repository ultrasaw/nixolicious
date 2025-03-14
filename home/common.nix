{ config, pkgs, lib, ... }:

{
  home.username = "gio";
  home.homeDirectory = "/home/gio";

  home.stateVersion = "24.11";

  programs = {
    home-manager.enable = true;
    yazi.enable = true; # terminal file manager
    btop.enable = true; # TUI for resource usage monitoring
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      ll = "ls -l";
      vim = "nvim";
      update = "sudo nixos-rebuild switch";

      # Git Aliases
      ga = "git add";
      gc = "git commit";
      gp = "git push";

      # Kubernetes
      k = "kubectl";
      kcurl = "k run tmp --restart=Never --rm -i --image=nginx:alpine -- curl -m 5";

      # Other Aliases
      ld = "lazydocker";
      docker-clean = "docker container prune -f && docker image prune -f && docker network prune -f && docker volume prune -f";
      cr = "cargo run";
      battery = "upower -i /org/freedesktop/UPower/devices/battery_BAT1";
      y = "yazi";
    };

    history = {
      size = 10000;
      path = "${config.xdg.dataHome}/zsh/zsh_history";
    };

    oh-my-zsh = {
      enable = true;
      plugins = [ ];
      theme = "agnoster";
    };

    initExtra = ''
      # Environment variables
      export do="--dry-run=client -o yaml"
      export now="--force --grace-period 0"

      # Source kubectl completion script
      source <(kubectl completion zsh)

      # kubeconfig from multiple .yaml files
      export KUBECONFIG="$HOME/.kube/cl-k8s-gitlab-runner-dev-01.yaml:$HOME/.kube/cl-k8s-workload-prod-01.yaml:$HOME/.kube/devcluster01-test.yaml:$HOME/.kube/devcluster01.yaml:$HOME/.kube/devcluster02.yaml:$HOME/.kube/internalservice-ng.yaml:$HOME/.kube/local.yaml:$HOME/.kube/prodcluster01-rke2.yaml:$HOME/.kube/workloaddev01-test.yaml:$HOME/.kube/workloaddev01.yaml"
    '';
  };

  programs.git = {
    enable = true;
    aliases = {
      pu = "push";
      co = "checkout";
      cm = "commit";
    };
  };

  # Define user environment packages
  home.packages = with pkgs; [
    htop
    alacritty
    neovim
    sublime
    google-chrome
    firefox

    unzip

    grim
    slurp
    swappy
    wl-clipboard

    nwg-bar

    kubectl
    k9s

    s3cmd

    openssl

    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
  ];

  fonts.fontconfig.enable = true;

}
