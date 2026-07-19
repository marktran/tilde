# Custom Window Title

Local Obsidian plugin that removes the app version from the window title.

Current format:

- `Note - Vault - Obsidian`
- or `Vault - Obsidian` when no note is active

## How it is managed

- Source of truth: `nix/files/obsidian/custom-window-title/` in this repo.
- `nix/home-manager/common/obsidian.nix` links it into each vault at
  `~/Obsidian/<Vault>/.obsidian/plugins/custom-window-title` on both Linux
  and macOS.
- Enabling the plugin is per-vault Obsidian state
  (`.obsidian/community-plugins.json`), which Obsidian rewrites itself, so it
  is not managed by Nix. Enable it once per vault under Settings → Community
  plugins.

## Development cycle

1. Edit `main.js` (window title format lives in `buildCustomTitle()`).
2. `make switch` to relink the store-backed files.
3. Reload the plugin in the running app:

   ```sh
   obsidian plugin:reload id=custom-window-title
   ```
