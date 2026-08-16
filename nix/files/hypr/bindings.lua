-- Personal keybindings. Omarchy's preinstalled app/webapp bindings are
-- disabled in hyprland.lua (omarchy_preinstalled_bindings = false). The
-- essential defaults (terminal/browser/file manager/editor) match the old
-- 3.x setup and are kept. SUPER+RETURN opens in the active terminal's cwd
-- by default now.

-- Tmux, upstream behavior: attach to (or create) the "Work" session.
o.bind("SUPER + ALT + RETURN", "Tmux", { omarchy = "terminal-tmux" })

-- Apps.
-- Herdr (upstream gates this behind preinstalled bindings). Launched as a
-- TUI so it gets the org.omarchy.herdr class for the workspace-7 rule in
-- windows.lua; focus = jump to the existing window instead of spawning more.
o.bind("SUPER + CTRL + RETURN", "Herdr", { tui = "herdr", focus = true })
-- Emacs frames attach to the systemd-managed daemon (linux.nix);
-- --alternate-editor= starts a daemon if it is somehow not running.
o.bind("SUPER + SHIFT + E", "Emacs", { focus = "^emacs$", launch = "emacsclient -c --alternate-editor=" })
o.bind("SUPER + SHIFT + M", "Music", "omarchy-launch-or-focus spotify")
o.bind("SUPER + SHIFT + T", "Activity", "uwsm-app -- xdg-terminal-exec -e btop")
o.bind("SUPER + SHIFT + D", "Docker", { tui = "lazydocker" })
-- Signal launches manually (menu); its workspace-6 rules live in windows.lua.
o.bind("SUPER + SHIFT + SLASH", "Passwords", "uwsm-app -- 1password")

-- Web apps.
o.bind("SUPER + SHIFT + A", "ChatGPT", 'omarchy-launch-or-focus-webapp chrome-chatgpt "https://chatgpt.com"')
o.bind("SUPER + SHIFT + P", "Google Photos", 'omarchy-launch-or-focus-webapp "Google Photos" "https://photos.google.com/"')
o.bind("SUPER + SHIFT + X", "X", 'omarchy-launch-or-focus-webapp X "https://x.com/"')
-- Superhuman has no public compose deep-link; open the app, `c` composes.
o.bind("SUPER + SHIFT + ALT + E", "New email", { webapp = "https://mail.superhuman.com/" })

-- ThinkPad Copilot key emits SUPER+SHIFT+code:201; Makima remaps that chord
-- to Right Control. Keep it from falling through to the Omarchy menu when
-- Makima is stopped.
hl.unbind("SUPER + SHIFT + code:201")
o.bind("XF86Tools", "Lock screen", "omarchy-system-lock")

-- ThinkPad F4/mic-mute key toggles Voxtype dictation instead of mic mute.
hl.unbind("XF86AudioMicMute")
o.bind("XF86AudioMicMute", "Toggle dictation", "voxtype record toggle")
-- Drop the default SUPER+CTRL+X dictation chord (hardware keys cover it).
hl.unbind("SUPER + CTRL + X")

-- Reorder tabs/windows within a Hyprland group.
o.bind("SUPER + CTRL + SHIFT + LEFT", "Move grouped window left", hl.dsp.group.move_window({ forward = false }))
o.bind("SUPER + CTRL + SHIFT + RIGHT", "Move grouped window right", hl.dsp.group.move_window({ forward = true }))

-- HHKB media keys.
local hhkb = { device = { inclusive = true, list = { "pfu-limited-hhkb-hybrid" } } }
o.bind("ALT_R + F4", "Previous track", "playerctl previous", hhkb)
o.bind("ALT_R + F5", "Play/pause", "playerctl play-pause", hhkb)
o.bind("ALT_R + F6", "Next track", "playerctl next", hhkb)

-- Topre REALFORCE 87 US: keys emitted by the -1 interface, not -keyboard.
-- XF86Launch6 mirrors the ThinkPad Mode key's color-scheme toggle; F4
-- mirrors the dictation toggle.
local topre = { device = { inclusive = true, list = { "topre-realforce-87-us-1" } } }
o.bind("XF86Launch6", "Toggle color scheme", "/home/mark/bin/toggle-color-scheme", topre)
o.bind("F4", "Toggle dictation", "voxtype record toggle", topre)
