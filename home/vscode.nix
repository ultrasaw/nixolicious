{ config, pkgs, lib, ... }:

let
  extensions = (with pkgs.vscode-extensions; [
    bbenoist.nix
    golang.go
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
  ]) ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
    {
      name = "kdl";
      publisher = "kdl-org";
      version = "2.1.3";
      sha256 = "sha256-Jssmb5owrgNWlmLFSKCgqMJKp3sPpOrlEUBwzZSSpbM=";
    }
  ];

  # create the wrapped VS Code package to disable gpu, otherwise flickering
  vscodeWithGpuDisabled = pkgs.symlinkJoin {
    name = "vscode-with-gpu-disabled";

    pname = pkgs.vscode.pname;
    version = pkgs.vscode.version;

    paths = [ pkgs.vscode ];
    buildInputs = [ pkgs.makeWrapper ]; # add tool to wrap the program
    postBuild = ''
      wrapProgram $out/bin/code --add-flags "--disable-gpu"
    '';
  };

in {
  programs.vscode = {
    enable = true;
    package = vscodeWithGpuDisabled;
    enableUpdateCheck = true;
    mutableExtensionsDir = true;
    extensions = extensions;

    userSettings = {
      # python.formatting.blackPath = "${pkgs.black}/bin/black";
      # python.defaultInterpreterPath = "./venv/bin/python";
      # python.terminal.activateEnvironment = true; # activate the selected interpreter in new terminals.

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
      "dataWrangler.outputRenderer.enabledTypes" = {
        "polars.dataframe.frame.DataFrame" = true;
        "polars.series.series.Series" = true;
        "pyspark.sql.dataframe.DataFrame" = true;
        "pyspark.sql.connect.dataframe.DataFrame" = true;
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
