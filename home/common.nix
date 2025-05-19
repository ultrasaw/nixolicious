{ config, pkgs, lib, ... }:

{

  home.username = "gio";
  home.homeDirectory = "/home/gio";

  home.stateVersion = "24.11";

  programs = {
    home-manager.enable = true;
    yazi.enable = true; # terminal file manager
    btop.enable = true; # TUI for resource usage monitoring
    bat.enable = true; # cat with syntax highlighting
    starship.enable = true;
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
      battery = "upower -i /org/freedesktop/UPower/devices/battery_BAT1";
      y = "yazi";
      zc = "zellij --layout compact";
      zs = "zellij --layout split";
    };

    history = {
      size = 10000;
      path = "${config.xdg.dataHome}/zsh/zsh_history";
    };

    oh-my-zsh = {
      enable = true;
      plugins = [ ];
      theme = "clean"; # agnoster, amuse, arrow, clean
    };

    initExtra = ''
      # --- Start: Custom Terminal Title ---

      export DISABLE_AUTO_TITLE="true"

      set_term_title() {
        local my_emoji="🥱" # 🫥 👾 🥱
        print -Pn "\e]0;''${my_emoji}\a"
      }

      autoload -Uz add-zsh-hook
      add-zsh-hook precmd set_term_title

      # --- End: Custom Terminal Title ---

      # https://github.com/alacritty/alacritty/issues/1408#issuecomment-467970836
      bindkey "^[[1;3C" forward-word
      bindkey "^[[1;3D" backward-word

      # ripgrep + fzf
      ff() {
        if [ ! "$#" -gt 0 ]; then echo "Need a string to search for!"; return 1; fi
        rg --files-with-matches --no-messages --hidden "$1" --glob "!.git/*" | fzf --preview "highlight -O ansi -l {} 2> /dev/null | rg --colors 'match:bg:yellow' --ignore-case --pretty --context 10 '$1' || rg --ignore-case --pretty --context 10 '$1' {}"
      }

      # ripgrep + fzf -> helix
      fh() {
        if [ ! "$#" -gt 0 ]; then echo "Need a string to search for!"; return 1; fi
        rg --files-with-matches --no-messages --hidden "$1" --glob "!.git/*" | fzf --preview "highlight -O ansi -l {} 2> /dev/null | rg --colors 'match:bg:yellow' --ignore-case --pretty --context 10 '$1' || rg --ignore-case --pretty --context 10 '$1' {}" | xargs hx
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
    userEmail = "giordano2407@gmail.com";
    userName = "gio";
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

  programs.kitty = {
    enable = true;
    shellIntegration.enableZshIntegration = false;
    theme = "Adwaita dark";

    font = {
      # Use the Nerd Font package installed above.
      # Important: The 'name' must match the font family name known to fontconfig.
      # Use `fc-list | grep "YourFontName"` to find the exact name if unsure.
      name = "JetBrainsMono Nerd Font"; # Construct the name based on the 'let' variable
      size = 15;
      # package = pkgs.kitty; # Usually defaults to the kitty package itself for font rendering support if needed.
    };

    # See: https://sw.kovidgoyal.net/kitty/conf/
    settings = {

      # --- Appearance ---
      background_opacity = "1.0"; # Slightly transparent (0.0 to 1.0)
      # macos_titlebar_color = "background"; # macOS specific: Blend title bar
      hide_window_decorations = "titlebar-only"; # Example: Hide titlebar on macOS/Wayland if desired
      window_padding_width = 10; # Padding around window edges
      cursor_shape = "Block"; # Beam, Block, Underline
      cursor_blink_interval = 0; # Disable cursor blinking

      # --- Behavior ---
      scrollback_lines = 10000; # Increase scrollback history
      copy_on_select = true; # Copy when selecting text
      strip_trailing_spaces = "smart"; # Keep spaces in commands, strip elsewhere
      enable_audio_bell = false; # No annoying bell sound
      confirm_os_window_close = 0; # 0 = Never ask before closing window

      # --- Tab Bar ---
      # tab_bar_edge = "bottom"; # top, bottom, hidden
      # tab_bar_style = "powerline"; # fade, separator, powerline, hidden
      # tab_powerline_style = "slanted"; # slanted, angled, round
      shell_integration = "no-title";

      # --- URL Handling ---
      # url_color = "#0087bd"; # Handled by theme usually
      # url_style = "dotted";
      open_url_modifiers = "ctrl+shift"; # Keys to press while clicking URL
      open_url_with = "default"; # Use default browser

      # --- Mouse ---
      # mouse_hide_wait = 3.0; # Hide mouse after 3s of inactivity
      # click_interval = 0.5; # Time for double/triple clicks

      # --- Performance ---
      # repaint_delay = 10;
      # input_delay = 3;
      sync_to_monitor = true; # Helps prevent tearing
    };

    # See: https://sw.kovidgoyal.net/kitty/actions/
    # Use `kitty --debug-keyboard` to find key names
    # keybindings = {
    #   # --- Navigation ---
    #   "kitty_mod+left" = "previous_window";
    #   "kitty_mod+right" = "next_window";
    #   "kitty_mod+up" = "previous_tab";
    #   "kitty_mod+down" = "next_tab";
    #   "kitty_mod+shift+," = "move_tab_backward";
    #   "kitty_mod+shift+." = "move_tab_forward";

    #   # --- Window/Tab Management ---
    #   "kitty_mod+t" = "new_tab"; # Default new tab
    #   "kitty_mod+w" = "close_tab"; # Close tab (default)
    #   "kitty_mod+enter" = "new_window"; # Default new window
    #   "kitty_mod+shift+enter" = "new_os_window"; # New OS window

    #   # --- Copy/Paste ---
    #   "ctrl+shift+c" = "copy_to_clipboard";
    #   "ctrl+shift+v" = "paste_from_clipboard";
    #   # "shift+insert"      = "paste_from_selection"; # Linux middle-click style paste

    #   # --- Font Size ---
    #   "kitty_mod+equal" = "increase_font_size";
    #   "kitty_mod+minus" = "decrease_font_size";
    #   "kitty_mod+backspace" = "restore_font_size";

    #   # --- Scrolling ---
    #   "kitty_mod+k" = "scroll_line_up";
    #   "kitty_mod+j" = "scroll_line_down";
    #   "kitty_mod+page_up" = "scroll_page_up";
    #   "kitty_mod+page_down" = "scroll_page_down";
    #   "kitty_mod+home" = "scroll_home";
    #   "kitty_mod+end" = "scroll_end";

    #   # --- Shell Interaction ---
    #   # Map Ctrl+Left/Right to move by word in many shells (sends Alt+B/F)
    #   "ctrl+left" = "send_text all \\x1b\\x62"; # Send Alt+B (backward-word)
    #   "ctrl+right" = "send_text all \\x1b\\x66"; # Send Alt+F (forward-word)

    #   # --- Misc ---
    #   "kitty_mod+shift+k" = "clear_terminal scrollback"; # Clear scrollback
    #   "kitty_mod+shift+f11" = "toggle_fullscreen";
    #   "kitty_mod+f1" = "show_scrollback"; # View scrollback in pager (less)
    #   "kitty_mod+," = "edit_config_file"; # Open kitty.conf for editing
    # };
  };

  # Define user environment packages
  home.packages = with pkgs; [
    htop
    lsof

    google-chrome
    firefox
    obsidian

    grim
    slurp
    swappy
    wl-clipboard

    nwg-bar

    unzip

    kubectl
    k9s
    kubernetes-helm

    unstable.opentofu
    unstable.terragrunt

    awscli2
    s3cmd
    aws-sam-cli

    openssl

    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
    # nerd-fonts.jetbrains-mono
    noto-fonts-emoji
  ];

  # fonts.fontconfig.enable = true;

}
