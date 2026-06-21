{ outOfStore, forceLinks, ... }:

{
  home.file = {
    # Emacs config submodule; Emacs writes elpa/, var/, eln-cache/, etc., so it
    # stays a live out-of-store link to the checkout (emacs.d submodule).
    ".emacs.d" = {
      source = outOfStore "emacs.d";
      force = forceLinks;
    };
    # NOTE: ~/.config/fish/fish_variables (fish universal vars) and local.fish
    # (machine-local, may hold secrets) are intentionally NOT managed here.
    # fish owns them natively as real files under ~/.config/fish, kept out of
    # this repo. config.fish sources local.fish by path if it exists.

    # Cross-platform git SSH signing wrapper (branches on darwin/linux).
    # Linux-only ~/bin scripts (spotify-control, toggle-color-scheme) live in
    # linux.nix.
    "bin/op-ssh-sign-wrapper" = {
      source = ../../files/bin/op-ssh-sign-wrapper;
      force = true;
    };

    ".hunspell_default" = {
      source = ../../files/hunspell/default;
      force = true;
    };
  };
}
