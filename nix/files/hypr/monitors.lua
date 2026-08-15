-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

hl.env("GDK_SCALE", "2")

-- ThinkPad X1 Carbon Gen 13 internal display.
hl.monitor({ output = "eDP-1", mode = "2880x1800@120", position = "auto", scale = 2 })

-- External display (5K) - Apple Studio Display XDR.
hl.monitor({ output = "DP-1", mode = "5120x2880@120", position = "auto", scale = 2 })

-- Clamshell mode reference (trigger on lid switch):
-- hl.bind("switch:on:Lid Switch", hl.dsp.exec_cmd('hyprctl keyword monitor "eDP-1, disable"'))
-- hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd('hyprctl keyword monitor "eDP-1,2880x1800@120,auto,2"'))
