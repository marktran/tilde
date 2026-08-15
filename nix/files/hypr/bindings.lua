-- Personal keybindings. Omarchy's preinstalled app/webapp bindings are
-- disabled in hyprland.lua (omarchy_preinstalled_bindings = false). The
-- essential defaults (terminal/browser/file manager/editor) match the old
-- 3.x setup and are kept. SUPER+RETURN opens in the active terminal's cwd
-- by default now.

-- Tmux session in the current directory (plain `tmux new`, no attach).
o.bind("SUPER + ALT + RETURN", "Tmux", 'uwsm-app -- xdg-terminal-exec --dir="$(omarchy-cmd-terminal-cwd)" tmux new')

-- Apps.
-- Herdr launch (upstream ships this in the preinstalled block we disable).
o.bind("SUPER + CTRL + RETURN", "Herdr", { omarchy = "terminal-herdr" })
o.bind("SUPER + SHIFT + E", "Emacs", { focus = "^emacs$", launch = "emacs" })
o.bind("SUPER + SHIFT + M", "Music", "omarchy-launch-or-focus spotify")
o.bind("SUPER + SHIFT + T", "Activity", "uwsm-app -- xdg-terminal-exec -e btop")
o.bind("SUPER + SHIFT + D", "Docker", "uwsm-app -- xdg-terminal-exec -e lazydocker")
o.bind("SUPER + SHIFT + S", "Signal", { focus = "signal", launch = "signal-desktop" })
o.bind("SUPER + SHIFT + SLASH", "Passwords", "uwsm-app -- 1password")

-- Web apps.
o.bind("SUPER + SHIFT + A", "ChatGPT", 'omarchy-launch-or-focus-webapp chrome-chatgpt "https://chatgpt.com"')
o.bind("SUPER + SHIFT + R", "Reflect", 'omarchy-launch-or-focus-webapp chrome-reflect "https://reflect.app"')
o.bind("SUPER + SHIFT + P", "Google Photos", 'omarchy-launch-or-focus-webapp "Google Photos" "https://photos.google.com/"')
o.bind("SUPER + SHIFT + X", "X", 'omarchy-launch-or-focus-webapp X "https://x.com/"')

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
o.bind("SUPER + CTRL + SHIFT + LEFT", "Move grouped window left", "hyprctl dispatch movegroupwindow b")
o.bind("SUPER + CTRL + SHIFT + RIGHT", "Move grouped window right", "hyprctl dispatch movegroupwindow f")

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
