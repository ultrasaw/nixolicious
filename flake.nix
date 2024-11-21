{
  description = "Nix configuration for my setup";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    hyprland.url = "github:hyprwm/Hyprland";
    nix-colors.url = "github:misterio77/nix-colors";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland-contrib = {
      url = "github:hyprwm/contrib";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, ... }@inputs: 
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      lib = nixpkgs.lib;
      theme = "sakura";
    in {
      nixConfig = {
        nix.settings.experimental-features = [ "nix-command" "flakes" ];
      };

      nixosConfigurations.tower = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit inputs theme;
        };
        modules = [
          ./hosts/tower/configuration.nix
          ./modules/base.nix
          ./modules/vscode.nix
          ./modules/greetd.nix
          ./modules/hyprland.nix
          # ./modules/gnome.nix
          # ./modules/nvidia.nix
          inputs.home-manager.nixosModules.default
        ];
      };
    };
}
