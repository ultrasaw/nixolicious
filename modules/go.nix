{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    unstable.go
    unstable.gopls
    unstable.gotools
    golangci-lint
    golangci-lint-langserver
  ];
}
