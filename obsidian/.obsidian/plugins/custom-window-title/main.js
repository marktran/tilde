const { Plugin } = require('obsidian');

module.exports = class CustomWindowTitlePlugin extends Plugin {
  onload() {
    this.scheduleTitleUpdate = this.scheduleTitleUpdate.bind(this);
    this.updateTitle = this.updateTitle.bind(this);

    this.registerEvent(this.app.workspace.on('file-open', this.scheduleTitleUpdate));
    this.registerEvent(this.app.workspace.on('active-leaf-change', this.scheduleTitleUpdate));
    this.registerEvent(this.app.workspace.on('layout-change', this.scheduleTitleUpdate));
    this.registerEvent(this.app.vault.on('rename', this.scheduleTitleUpdate));
    this.registerEvent(this.app.vault.on('delete', this.scheduleTitleUpdate));

    this.register(() => {
      if (this.titleTimer) {
        window.clearTimeout(this.titleTimer);
      }
    });

    this.app.workspace.onLayoutReady(() => this.scheduleTitleUpdate());
    this.scheduleTitleUpdate();
  }

  onunload() {
    this.restoreDefaultTitle();
  }

  scheduleTitleUpdate() {
    if (this.titleTimer) {
      window.clearTimeout(this.titleTimer);
    }

    this.titleTimer = window.setTimeout(() => this.updateTitle(), 0);
  }

  updateTitle() {
    if (typeof document === 'undefined') {
      return;
    }

    document.title = this.buildCustomTitle();
  }

  buildCustomTitle() {
    const file = this.app.workspace.getActiveFile();
    const note = file?.basename?.trim();
    const vault = this.app.vault.getName()?.trim() || 'Obsidian';

    if (note) {
      return `${note} - ${vault} - Obsidian`;
    }

    return `${vault} - Obsidian`;
  }

  restoreDefaultTitle() {
    if (typeof document === 'undefined') {
      return;
    }

    const file = this.app.workspace.getActiveFile();
    const note = file?.basename?.trim();
    const vault = this.app.vault.getName()?.trim() || 'Obsidian';
    const version = this.app.version ? ` ${this.app.version}` : '';

    if (note) {
      document.title = `${note} - ${vault} - Obsidian${version}`;
      return;
    }

    document.title = `${vault} - Obsidian${version}`;
  }
};
