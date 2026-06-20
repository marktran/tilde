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

      mkHome = { system, homeDirectory, forceStowLinks ? false, modules ? [ ] }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };

          extraSpecialArgs = {
            inherit inputs username homeDirectory stateVersion forceStowLinks;
            checkoutPath = "${homeDirectory}/src/mark/tilde";
          };

          modules = [
            ./nix/home-manager/common.nix
          ] ++ modules;
        };

      linuxConfig = mkHome {
        system = "x86_64-linux";
        homeDirectory = "/home/mark";
        forceStowLinks = true;
        modules = [
          ./nix/home-manager/linux.nix
          ./nix/hosts/x1-carbon/home.nix
        ];
      };

      macConfig = mkHome {
        system = "aarch64-darwin";
        homeDirectory = "/Users/mark";
        modules = [
          ./nix/home-manager/darwin.nix
          ./nix/hosts/macbook-air/home.nix
        ];
      };
    in
    {
      homeConfigurations = {
        # Primary, stable public names used in the daily workflow.
        linux = linuxConfig;
        mac = macConfig;

        # Host-specific aliases. Identical to linux/mac; provided so the
        # actual machines can be referenced by name.
        x1-carbon = linuxConfig;
        macbook-air = macConfig;
      };
    };
}
