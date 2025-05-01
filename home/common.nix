{ config, pkgs, lib, ... }:

{

  home.stateVersion = "24.11";

  programs = {
    home-manager.enable = true;
    yazi.enable = true; # terminal file manager
    btop.enable = true; # TUI for resource usage monitoring
    bat.enable = true; # cat with syntax highlighting
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      ll = "ls -l";
      vim = "nvim";

      # Git Aliases
      ga = "git add";
      gc = "git commit";
      gp = "git push";

      # cat
      cat = "bat --style=numbers --color=always -P";

      # fzf
      fp = "fzf --preview 'bat --style=numbers --color=always {}'"; # file preview

      # Kubernetes
      k = "kubectl";
      kcurl = "k run tmp --restart=Never --rm -i --image=nginx:alpine -- curl -m 5";

      # Other Aliases
      ld = "lazydocker";
      docker-clean = "docker container prune -f && docker image prune -f && docker network prune -f && docker volume prune -f";
      cr = "cargo run";
      y = "yazi";
      zc = "zellij --layout compact";
      zs = "zellij --layout split";
    };

    history = {
      size = 10000;
      path = "${config.xdg.dataHome}/zsh/zsh_history";
    };

    oh-my-zsh = {
      enable = false;
      plugins = [ ];
      theme = "clean"; # agnoster, amuse, arrow, clean
    };

    initExtra = ''
      # https://github.com/alacritty/alacritty/issues/1408#issuecomment-467970836
      bindkey "^[[1;3C" forward-word
      bindkey "^[[1;3D" backward-word

      # ripgrep + fzf
      ff() {
        if [ ! "$#" -gt 0 ]; then echo "Need a string to search for!"; return 1; fi
        rg --files-with-matches --no-messages --hidden "$1" | fzf --preview "highlight -O ansi -l {} 2> /dev/null | rg --colors 'match:bg:yellow' --ignore-case --pretty --context 10 '$1' || rg --ignore-case --pretty --context 10 '$1' {}"
      }

      # ripgrep + fzf -> helix
      fh() {
        if [ ! "$#" -gt 0 ]; then echo "Need a string to search for!"; return 1; fi
        rg --files-with-matches --no-messages --hidden "$1" | fzf --preview "highlight -O ansi -l {} 2> /dev/null | rg --colors 'match:bg:yellow' --ignore-case --pretty --context 10 '$1' || rg --ignore-case --pretty --context 10 '$1' {}" | xargs hx
      }

      # Environment variables
      export do="--dry-run=client -o yaml"
      export now="--force --grace-period 0"

      # Source kubectl completion script
      source <(kubectl completion zsh)

      # kubeconfig from multiple .yaml files
      export KUBECONFIG="$HOME/.kube/cl-k8s-gitlab-runner-dev-01.yaml:$HOME/.kube/cl-k8s-workload-prod-01.yaml:$HOME/.kube/devcluster01-test.yaml:$HOME/.kube/devcluster01.yaml:$HOME/.kube/devcluster02.yaml:$HOME/.kube/internalservice-ng.yaml:$HOME/.kube/local.yaml:$HOME/.kube/prodcluster01-rke2.yaml:$HOME/.kube/workloaddev01-test.yaml:$HOME/.kube/workloaddev01.yaml"
    '';
  };

  # ls replacement
  programs.eza.enable = true;
  programs.eza.enableZshIntegration = true;

  programs.git = {
    enable = true;
    aliases = {
      pu = "push";
      co = "checkout";
      cm = "commit";
    };
  };

  # a 'post-modern' text editor
  programs.helix = {
    enable = true;
    defaultEditor = true;
  };

  # a modern tmux
  programs.zellij = {
    enable = true;
    enableZshIntegration = false;
  };

  # a better 'cd'
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  # a fuzzy finder
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  # a recursive search tool
  programs.ripgrep = {
    enable = true;
  };

  # Define user environment packages
  home.packages = with pkgs; [
    htop
    # alacritty
    neovim

    terraform

    unzip

    kubectl
    k9s

    awscli2
    s3cmd
    aws-sam-cli

    openssl

    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
  ];

  # fonts.fontconfig.enable = true;

}
