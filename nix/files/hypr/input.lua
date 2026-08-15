-- Personal input overrides. See https://wiki.hypr.land/Configuring/Basics/Variables/#input

hl.config({
  input = {
    -- Change speed of keyboard repeat.
    repeat_rate = 40,
    repeat_delay = 300,

    -- Start with numlock on by default.
    numlock_by_default = true,

    -- Remap Caps Lock to Left Control.
    kb_options = "caps:ctrl_modifier",

    -- Increase sensitivity for mouse/trackpad (default: 0).
    sensitivity = 0.15,

    touchpad = {
      -- Use natural (inverse) scrolling.
      natural_scroll = true,

      -- Use two-finger clicks for right-click instead of lower-right corner.
      clickfinger_behavior = true,

      -- Control the speed of your scrolling.
      scroll_factor = 0.4,

      -- Disable tap to click.
      tap_to_click = false,
    },
  },
})

-- Scroll nicely in the terminal.
o.window("(Alacritty|kitty|foot)", { scroll_touchpad = 1.5 })
o.window("com.mitchellh.ghostty", { scroll_touchpad = 0.5 })

-- Per-device settings.
hl.device({ name = "at-translated-set-2-keyboard", kb_options = "caps:ctrl_modifier" })
hl.device({ name = "tpps/2-elan-trackpoint", sensitivity = -0.4 }) -- Lower sensitivity for TrackPoint
hl.device({ name = "mx-ergo-s-plus-mouse", sensitivity = -0.3 }) -- Logitech MX Ergo trackball

-- Touchpad gestures for changing workspaces.
hl.config({
  gestures = {
    workspace_swipe_distance = 400,
    workspace_swipe_cancel_ratio = 0.3,
  },
})
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- 4-finger column moves for the scrolling layout.
hl.gesture({ fingers = 4, direction = "left", action = function()
  hl.exec_cmd("hyprctl dispatch layoutmsg 'move +col'")
end })
hl.gesture({ fingers = 4, direction = "right", action = function()
  hl.exec_cmd("hyprctl dispatch layoutmsg 'move -col'")
end })
