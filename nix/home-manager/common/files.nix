{ outOfStore, forceLinks, ... }:

{
  # Herdr edits this file from its settings UI, so keep it as a writable
  # out-of-store link rather than a read-only Nix store copy. Runtime state,
  # sockets, and logs remain unmanaged in ~/.config/herdr.
  xdg.configFile."herdr/config.toml" = {
    source = outOfStore "nix/files/herdr/config.toml";
    force = forceLinks;
  };

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

    # Shadows ~/.local/bin/claude ($HOME/bin comes first in PATH) to route
    # Claude Code through the Cloudflare AI Gateway using the credential in
    # ~/.pi/agent/auth.json instead of its own Anthropic login.
    "bin/claude" = {
      source = ../../files/bin/claude;
      force = true;
    };

    # Pi reports available package updates but does not apply them. Keep
    # unpinned npm/git packages current before each top-level Pi session;
    # nested agents and explicit package-management commands bypass this.
    "bin/pi" = {
      source = ../../files/bin/pi;
      force = true;
    };

    ".hunspell_default" = {
      source = ../../files/hunspell/default;
      force = true;
    };

    # Enchant personal wordlists (used by Emacs jinx). Enchant appends words
    # at runtime (jinx `$'), so it stays a live out-of-store link. Linked at
    # the directory level so new wordlists/exclusion files land in the repo.
    ".config/enchant" = {
      source = outOfStore "nix/files/enchant";
      force = forceLinks;
    };
  };
}
