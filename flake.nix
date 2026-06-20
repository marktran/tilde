{
  description = "Mark's dotfiles, managed with Home Manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ home-manager, nixpkgs, ... }:
    let
      username = "mark";
      stateVersion = "26.05";

      mkHome = { system, homeDirectory, modules ? [ ] }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };

          extraSpecialArgs = {
            inherit inputs username homeDirectory stateVersion;
            checkoutPath = "${homeDirectory}/src/mark/tilde";
          };

          modules = [
            ./nix/home-manager/common.nix
          ] ++ modules;
        };
    in
    {
      homeConfigurations = {
        linux = mkHome {
          system = "x86_64-linux";
          homeDirectory = "/home/mark";
          modules = [
            ./nix/home-manager/linux.nix
            ./nix/hosts/x1-carbon/home.nix
          ];
        };

        mac = mkHome {
          system = "aarch64-darwin";
          homeDirectory = "/Users/mark";
          modules = [
            ./nix/home-manager/darwin.nix
            ./nix/hosts/macbook-air/home.nix
          ];
        };
      };
    };
}
