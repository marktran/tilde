// Range-fix for Apple Studio Display XDR over DP on this ThinkPad
// (Lunar Lake, xe driver). The link carries full-range RGB but the display
// receives limited-range signaling, so it expands white 235 -> 255
// (scale-only; black stays 0) and tone-maps a highlight knee near ~235.
// Compensation: scale white to 212 (displayed ~230, below the knee).
//
// Managed by ~/.config/hypr/monitors.lua: applied only while the XDR
// display is connected; disable via the apple_xdr_range_fix flag there.
// Note: kernel 7.1.x already contains the nearest upstream fix
// (drm/i915/dp VSC dynamic range, 1ae15b6c796) - this is a distinct,
// still-unfixed bug. Re-test after kernel updates: hypr-xdr-range-test
#version 300 es
precision highp float;
in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

void main() {
    vec4 pixColor = texture(tex, v_texcoord);
    pixColor.rgb = pixColor.rgb * (212.0 / 255.0);
    fragColor = pixColor;
}
