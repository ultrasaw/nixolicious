{ config, pkgs, lib, ... }:

{
  programs.vscode = {
    enable = true;
    enableUpdateCheck = false;
    mutableExtensionsDir = false;

    extensions = with pkgs.vscode-extensions; [
      bbenoist.nix
      golang.go
      ms-python.python
      github.github-vscode-theme
      # vscodevim.vim
      yzhang.markdown-all-in-one
      tamasfe.even-better-toml
      tal7aouy.icons
      ms-kubernetes-tools.vscode-kubernetes-tools
      redhat.vscode-yaml
      oderwat.indent-rainbow
      hashicorp.terraform
      eamodio.gitlens
      ms-azuretools.vscode-docker
    ];

    userSettings = {
      "git.confirmSync" = false;
      "workbench.iconTheme" = "icons";
      "window.zoomLevel" = 2.2;
      # "terminal.integrated.fontFamily" = "monospace";
      "editor.mouseWheelScrollSensitivity" = 3;
      "editor.fontFamily" = "'JetBrains Mono', Consolas, 'Courier New', monospace";
      "editor.fontSize" = 13;
      "editor.fontLigatures" = true;
      "editor.letterSpacing" = 0.4;
      "editor.smoothScrolling" = true;
      "workbench.colorTheme" = "GitHub Dark";
      "workbench.colorCustomizations" = {
        "editor.background" = "#1c1f21";
        "terminal.background" = "#1c1f21";
      };
      "editor.tokenColorCustomizations" = {
        textMateRules = [
          {
            scope = [ "keyword" ];
            settings = { foreground = "#e9ce30"; };
          }
          {
            scope = "constant.other.option";
            settings = { foreground = "#afeee3"; };
          }
          {
            scope = [
              "string.quoted.double.json"
              "variable.other.member.hcl"
              "meta.block.hcl"
              "source.hcl.terraform"
            ];
            settings = { foreground = "#afdbee"; };
          }
          {
            scope = [
              "keyword.control.go"
              "constant.language.boolean.yaml"
            ];
            settings = { foreground = "#eeac76"; };
          }
          {
            scope = [];
            settings = { foreground = "#d37dcc"; };
          }
          {
            scope = [
              "entity.name.tag.yaml"
              "entity.name.function"
              "variable.other.readwrite.terraform"
            ];
            settings = { foreground = "#ddaedc"; };
          }
          {
            scope = [ "constant.other.placeholder" ];
            settings = { foreground = "#4cc2dc"; };
          }
          {
            scope = [ "constant.numeric" ];
            settings = { foreground = "#46cca1"; };
          }
        ];
      };
      "indentRainbow.excludedLanguages" = [
        "go"
        "plaintext"
        "python"
        "r"
        "nix"
      ];
      "terraform.languageServer.enable" = true;
    };
  };
}
