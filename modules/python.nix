{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Core Python interpreter from unstable
    python313

    pyright        # Pyright is a full-featured, standards-based static type checker for Python
    black          # Code formatter
    isort          # Import sorter
  ];
}
