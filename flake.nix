{
  description = "Nix configuration for my setup";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    hyprland.url = "github:hyprwm/Hyprland";
    nix-colors.url = "github:misterio77/nix-colors";
    # stylix.url = "github:danth/stylix";
    niri-stable.url = "github:YaLTeR/niri/v25.02";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland-contrib = {
      url = "github:hyprwm/contrib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };

    # Scrolling window manager
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    astal = {
      url = "github:aylur/astal";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, ... }@inputs: 
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      lib = nixpkgs.lib;
      theme = "sakura";
      # unstablePkgs = nixpkgs-unstable.legacyPackages.${system};

      # define the overlay function
      unstable-overlay = final: prev: {
        unstable = inputs.nixpkgs-unstable.legacyPackages.${prev.system};
      };

    in {
      nixConfig = {
        nix.settings.experimental-features = [ "nix-command" "flakes" ];
      };

      nixosConfigurations.tower = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit inputs theme system;
        };
        modules = [
          { nixpkgs.overlays = [ unstable-overlay ]; }
          # base
          ./hosts/tower/configuration.nix
          ./modules/base.nix
          ./modules/python.nix
          ./modules/go.nix
          ./modules/rust.nix
          ./modules/nvidia.nix

          # niri
          ./modules/niri.nix
          ./modules/greetd_niri.nix
          inputs.niri.nixosModules.niri

          # gnome
          # ./modules/gnome.nix

          # hyprland
          # ./modules/greetd.nix
          # ./modules/hyprland.nix
          # ./modules/stylix.nix
          
          inputs.home-manager.nixosModules.default
          # inputs.stylix.nixosModules.stylix
        ];
      };
      nixosConfigurations.lenovo = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit inputs theme system;
        };
        modules = [
          ./hosts/lenovo/configuration.nix
          ./modules/base.nix
	        ./modules/gnome.nix
          # ./modules/greetd.nix
          # ./modules/hyprland.nix
          ./modules/python.nix
          ./modules/go.nix
          ./modules/rust.nix
          ./modules/vpn-ndc2.nix
          inputs.home-manager.nixosModules.default
          # inputs.stylix.nixosModules.stylix
        ];
      };
    };
}
