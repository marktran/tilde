{
  description = "Mark's dotfiles, managed with Home Manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ home-manager, nixpkgs, nix-darwin, ... }:
    let
      username = "mark";
      stateVersion = "26.05";

      # Shared specialArgs for the Home Manager modules. Used both standalone
      # and when Home Manager is folded into nix-darwin.
      #
      # forceLinks: when true, Home Manager overwrites pre-existing files at a
      # link target instead of erroring. Enabled on Linux (the targets were
      # audited); kept conservative (false) on macOS.
      homeExtraArgs = { homeDirectory, forceLinks }: {
        inherit inputs username homeDirectory stateVersion forceLinks;
        checkoutPath = "${homeDirectory}/src/mark/tilde";
      };

      # macOS Home Manager module list (common + darwin + host).
      macHomeModules = [
        ./nix/home-manager/common.nix
        ./nix/home-manager/darwin.nix
        ./nix/hosts/macbook-air/home.nix
      ];

      mkHome = { system, homeDirectory, forceLinks ? false, modules ? [ ] }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };

          extraSpecialArgs = homeExtraArgs { inherit homeDirectory forceLinks; };

          modules = [
            ./nix/home-manager/common.nix
          ] ++ modules;
        };

      linuxConfig = mkHome {
        system = "x86_64-linux";
        homeDirectory = "/home/mark";
        forceLinks = true;
        modules = [
          ./nix/home-manager/linux.nix
          ./nix/hosts/x1-carbon/home.nix
        ];
      };

      # Standalone Home Manager config for macOS. Kept as a rollback path: on
      # macOS the primary workflow is now `darwin-rebuild switch` (Home Manager
      # is folded into nix-darwin below). Do not run this standalone config
      # while nix-darwin owns the Home Manager profile.
      macConfig = mkHome {
        system = "aarch64-darwin";
        homeDirectory = "/Users/mark";
        modules = [
          ./nix/home-manager/darwin.nix
          ./nix/hosts/macbook-air/home.nix
        ];
      };

      # nix-darwin system config for macOS, with Home Manager folded in so a
      # single `darwin-rebuild switch` activates both system and user env.
      macDarwin = nix-darwin.lib.darwinSystem {
        specialArgs = { inherit inputs; };
        modules = [
          ./nix/darwin/configuration.nix
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            # Keep home.packages in ~/.nix-profile/bin (HM default), matching
            # the Linux setup and the fish PATH design that pins that dir last.
            # useUserPackages = true would instead route them to
            # /etc/profiles/per-user/$USER/bin, which the fish PATH does not
            # include (it would drop direnv off PATH).
            home-manager.useUserPackages = false;
            home-manager.extraSpecialArgs = homeExtraArgs {
              homeDirectory = "/Users/mark";
              forceLinks = false;
            };
            home-manager.users.${username}.imports = macHomeModules;
          }
        ];
      };
    in
    {
      homeConfigurations = {
        # Primary, stable public names used in the daily workflow.
        linux = linuxConfig;

        # macOS standalone Home Manager kept for evaluation/rollback only.
        mac = macConfig;

        # Host-specific aliases. Identical to linux/mac; provided so the
        # actual machines can be referenced by name.
        x1-carbon = linuxConfig;
        macbook-air = macConfig;
      };

      darwinConfigurations = {
        # Primary macOS workflow: `darwin-rebuild switch --flake .#mac`.
        mac = macDarwin;
        macbook-air = macDarwin;
      };
    };
}
