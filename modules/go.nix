{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    unstable.go
    unstable.gopls
    unstable.gotools
    unstable.golangci-lint
    unstable.golangci-lint-langserver
  ];
}
