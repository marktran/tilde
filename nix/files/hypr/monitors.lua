-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

hl.env("GDK_SCALE", "2")

-- ThinkPad X1 Carbon Gen 13 internal display.
hl.monitor({ output = "eDP-1", mode = "2880x1800@120", position = "auto", scale = 2 })

-- External display (5K) - Apple Studio Display XDR.
-- 10-bit output; sRGB preset (the display's own sRGB emulation handles gamut).
hl.monitor({ output = "DP-1", mode = "5120x2880@120", position = "auto", scale = 2, bitdepth = 10, cm = "srgb" })

-- ===========================================================================
-- WORKAROUND: Apple Studio Display XDR limited-range crush (diagnosed 2026-08)
-- ===========================================================================
-- The xe driver (Lunar Lake) sends full-range RGB but signals limited range,
-- so the display expands white 235 -> 255 (scale-only; black stays 0) and
-- tone-maps a highlight knee near ~235. Symptom: near-whites merge (e.g. no
-- card borders on white websites). Verified display-side with test strips;
-- macOS unaffected. Kernel 7.1.x already has the nearest upstream fix
-- (drm/i915/dp VSC dynamic range, 1ae15b6c796), so this is a distinct,
-- still-unfixed driver bug with no ETA.
--
-- The shader is applied only while this display is connected.
--
-- TO DISABLE: set apple_xdr_range_fix = false below, then `hyprctl reload`.
-- TO RE-TEST after kernel updates: disable as above, run
-- `hypr-xdr-range-test` (in ~/.config/hypr/scripts/); if all white squares
-- are then distinguishable, the bug is fixed: delete this block, the shader
-- (shaders/limited-range-fix.frag), the test script, and their entries in
-- nix/home-manager/linux.nix.
local apple_xdr_range_fix = true

local function xdr_display_present()
  for _, mon in ipairs(hl.get_monitors()) do
    if mon.description and mon.description:find("Studio XDR") then
      return true
    end
  end
  return false
end

local function update_xdr_shader()
  if apple_xdr_range_fix and xdr_display_present() then
    hl.config({ ["decoration.screen_shader"] = os.getenv("HOME") .. "/.config/hypr/shaders/limited-range-fix.frag" })
  else
    hl.config({ ["decoration.screen_shader"] = "" })
  end
end

hl.on("monitor.added", update_xdr_shader)
hl.on("monitor.removed", update_xdr_shader)
update_xdr_shader()

-- Clamshell mode reference (trigger on lid switch):
-- hl.bind("switch:on:Lid Switch", hl.dsp.exec_cmd('hyprctl keyword monitor "eDP-1, disable"'))
-- hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd('hyprctl keyword monitor "eDP-1,2880x1800@120,auto,2"'))
