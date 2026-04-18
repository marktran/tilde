# Custom Window Title

Local Obsidian plugin that removes the app version from the window title.

Current format:

- `Note - Vault - Obsidian`
- or `Vault - Obsidian` when no note is active

This plugin is managed from:

- `~/src/mark/tilde/obsidian/.obsidian/plugins/custom-window-title`

To use it in another vault with GNU Stow:

```bash
mkdir -p /path/to/Vault/.obsidian/plugins
stow -d ~/src/mark/tilde -t /path/to/Vault obsidian
```

Create the target vault's `.obsidian/plugins` directory first so Stow links only this plugin, not the whole plugins directory.

Then enable community plugins in that vault and enable `custom-window-title`.

If you want to change the format later, edit `main.js` and modify `buildCustomTitle()`.
