{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    go
    gopls
    golangci-lint
    golangci-lint-langserver
  ];
}
