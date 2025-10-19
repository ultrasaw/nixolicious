{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    unstable.claude-code
    unstable.opencode
  ];
}
