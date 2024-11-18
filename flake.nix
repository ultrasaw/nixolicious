{
  description = "Nix configuration for my setup";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, ... }@inputs: 
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      nixConfig = {
        nix.settings.experimental-features = [ "nix-command" "flakes" ];
      };

      nixosConfigurations.tower = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit inputs;
        };
        modules = [
          ./hosts/tower/configuration.nix
          ./modules/base.nix
          ./modules/vscode.nix
          ./modules/hyprlnd.nix
          ./modules/nvidia.nix
          inputs.home-manager.nixosModules.default
        ];
      };
    };
}
