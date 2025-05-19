{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    unstable.go
    unstable.gopls
    golangci-lint
    golangci-lint-langserver
  ];
}
