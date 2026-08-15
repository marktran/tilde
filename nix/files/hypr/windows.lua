-- Custom window rules. See https://wiki.hypr.land/Configuring/Basics/Window-Rules/

-- Files window.
o.window("^org\\.gnome\\.Nautilus$", { float = true, center = true })

-- Typora print dialog.
o.window({ class = "^Typora$", title = "^Print$" }, { float = true, center = true })

-- Print settings.
o.window({ class = "^system-config-printer$", title = "^Print Settings.*$" }, { float = true, center = true })

-- Pin main browser window to workspace 1.
o.window("^(chromium|brave-origin-beta|brave-browser)$", { workspace = "1" })

-- Pin Emacs to workspace 2.
o.window("emacs", { workspace = "2" })

-- Pin ChatGPT, Todoist, and Obsidian to workspace 3.
o.window("^(chrome|brave)-chatgpt\\.com__-Default$", { workspace = "3" })
o.window("^(chrome|brave)-app\\.todoist\\.com__-Default$", { workspace = "3", group = "set" })
o.window("^obsidian$", { workspace = "3", group = "set" })

-- Pin Feedbin to workspace 4.
o.window("^(chrome|brave)-feedbin\\.com__-Default$", { workspace = "4" })

-- Pin Spotify to workspace 5.
o.window("^Spotify$", { workspace = "5" })

-- Pin chat apps to workspace 6 and group them.
o.window("signal", { workspace = "6", group = "set" })
o.window("chrome-discord.com__channels_@me-Default", { workspace = "6", group = "set" })
o.window("^org\\.telegram\\.desktop$", { workspace = "6", group = "set" })

-- Pin Herdr (persistent agent multiplexer) to workspace 7.
o.window("^org\\.omarchy\\.herdr$", { workspace = "7" })

-- Pin Typora to workspace 9.
o.window("Typora", { workspace = "9" })

-- Pin 1Password to scratchpad.
o.window("1password", { workspace = "special:scratchpad", center = true })

-- Make mpv behave like PiP overlays (float + pin across workspaces).
-- Dedicated tag so Omarchy's fixed pip size rule does not lock dimensions.
o.window("^(mpv)$", { tag = "+mpv-pip" })
o.window({ tag = "mpv-pip" }, { tag = "-default-opacity" })
o.window({ tag = "mpv-pip", fullscreen = false }, { float = true, pin = true, keep_aspect_ratio = true, center = true })
o.window({ tag = "mpv-pip" }, { border_size = 0, opacity = "1 1" })

-- Place browser PiP windows in the bottom-right quadrant, overriding
-- Omarchy's corner placement (later rules win). Hard-coded for eDP-1
-- (2880x1800 @ scale 2 = 1440x900 logical):
--   x = 1440*3/4 - 600/2 = 780
--   y =  900*3/4 - 338/2 = 506
o.window({ tag = "pip" }, { size = "600 338", move = "780 506" })
