# Emacs

## Gmail and Notmuch on Linux

The Linux Home Manager configuration provides the external mail stack used by
`emacs.d/settings/notmuch.el`:

```text
Gmail <-> Lieer (gmi) <-> ~/Maildir + Notmuch <-> Emacs
```

This configuration is Linux-only. It is declared in
`nix/home-manager/linux-mail.nix`, imported by
`nix/home-manager/linux.nix`, and is not part of the shared or macOS Home
Manager configurations.

### Components

- **Lieer (`gmi`)** uses the Gmail OAuth API to download messages, synchronize
  Gmail labels with Notmuch tags, and send messages. It does not require IMAP,
  msmtp, a Gmail password, or a Gmail app password.
- **Notmuch** indexes the local Maildir and provides search and tag operations.
- **Emacs Notmuch** is the user interface. Its settings and keybindings live in
  `emacs.d/settings/notmuch.el`. Like the other files in `emacs.d/settings`, it
  is loaded on every platform; the external commands it invokes are provisioned
  only on Linux.
- **systemd** runs Lieer automatically every five minutes after Gmail has been
  authorized.

Home Manager also creates three helper commands:

- `notmuch-gmail-auth` — initialize Notmuch and perform Gmail OAuth
  authorization.
- `notmuch-sync` — synchronize messages and tags immediately.
- `notmuch-sendmail` — send an Emacs message through the Gmail API.

### Local state

The generated configuration and mutable state are kept in these locations:

| Path | Purpose |
| --- | --- |
| `~/.config/notmuch/default/config` | Home Manager-generated Notmuch configuration |
| `~/Maildir/.notmuch` | Notmuch/Xapian search database |
| `~/Maildir/gmail/mail` | Messages downloaded by Lieer |
| `~/Maildir/gmail/.gmailieer.json` | Home Manager-generated Lieer configuration |
| `~/Maildir/gmail/.credentials.gmailieer.json` | Machine-local Gmail OAuth credentials |
| `~/Maildir/gmail/.state.gmailieer.json` | Mutable Lieer synchronization state |

Mail, indexes, OAuth credentials, and Lieer state are machine-local and are not
stored in Git.

### Installation and one-time authorization

Apply the Linux Home Manager configuration from the repository root:

```sh
make switch
```

Then complete the interactive OAuth flow and initial download:

```sh
notmuch-gmail-auth
notmuch-sync
```

`notmuch-gmail-auth` initializes the Notmuch database and opens Google's OAuth
flow in a browser. Lieer's shared OAuth client is used by default. If that
client is unavailable, download a Google Desktop OAuth client file and run:

```sh
notmuch-gmail-auth -c /path/to/client_secret.json
```

The first `notmuch-sync` downloads the complete Gmail mailbox. It may take a
while and use substantial disk space. Running it manually is useful for seeing
initial progress.

Restart Emacs after the initial installation, then use `SPC m` to open the
Notmuch Inbox directly. Run `M-x notmuch` when the Dashboard is needed.

### Routine synchronization

Routine manual synchronization is not required. The `lieer-gmail.timer`
systemd user timer runs every five minutes. Its service is skipped until the
OAuth credential file exists.

To synchronize immediately:

- Run `notmuch-sync` in a shell; or
- Press `G` in a Notmuch buffer, which runs `notmuch-sync` and refreshes the
  current view.

Tag changes made in Emacs normally remain local until synchronization. Archive
(`e`), Trash (`#`), Spam (`!`), and Starred (`s`) actions each request a
debounced background sync immediately; rapid operations are combined, and
another sync is queued when one is already running. Lieer pushes the local
tags to Gmail first and then pulls remote changes. If the systemd timer is
using the repository, Emacs retries after its lock is released.

Gmail's system labels map to these Notmuch tags:

| Gmail label | Notmuch tag |
| --- | --- |
| `INBOX` | `inbox` |
| `UNREAD` | `unread` |
| `STARRED` | `flagged` |
| `SENT` | `sent` |
| `DRAFT` | `draft` |
| `SPAM` | `spam` |
| `TRASH` | `trash` |

Archiving removes `inbox` and is bound only to `e`. Deleting from the
configured Notmuch tag menu adds
`trash` rather than Notmuch's internal `deleted` tag, allowing the operation to
propagate to Gmail. Lieer ignores `deleted` so superseded Notmuch drafts do not
create a non-standard Gmail label.

### Sending mail

Emacs uses `notmuch-sendmail`, which passes the message to `gmi send` and the
Gmail API. Gmail creates the authoritative Sent copy. Consequently,
`notmuch-fcc-dirs` is `nil` in the Emacs configuration; creating another local
Fcc would result in a duplicate that Lieer cannot upload.

### Diagnostics

Check the timer and its most recent service run:

```sh
systemctl --user status lieer-gmail.timer
systemctl --user status lieer-gmail.service
journalctl --user -u lieer-gmail.service
```

Check the indexed message count:

```sh
notmuch count '*'
```

If synchronization reports missing authorization, rerun
`notmuch-gmail-auth`. After changing `nix/home-manager/linux-mail.nix`, apply it
with `make switch`.
