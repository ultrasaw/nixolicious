{ config, pkgs, ... }:

{
  # Enable Visual Studio Code with extensions
  programs.vscode = {
    enable = true;
    extensions = with pkgs.vscode-extensions; [
      bbenoist.nix
      golang.go
      ms-python.python
      github.github-vscode-theme
      vscodevim.vim
      yzhang.markdown-all-in-one
    ];
  };

  # Other Home Manager settings
  programs.zsh.enable = true;

  # Define user environment packages
  home.packages = with pkgs; [
    htop
    neofetch
  ];
}
