local mp = require("mp")

local shown = false
local hold_seconds = 24 * 60 * 60 -- effectively persistent until toggled off

local function playlist_text()
    return mp.command_native({ "expand-text", "${playlist}" }) or "Playlist unavailable"
end

local function show_playlist()
    mp.osd_message(playlist_text(), hold_seconds)
    shown = true
end

local function hide_playlist()
    mp.osd_message("", 0)
    shown = false
end

local function toggle_playlist()
    if shown then
        hide_playlist()
    else
        show_playlist()
    end
end

local function refresh_playlist()
    if shown then
        show_playlist()
    end
end

mp.register_script_message("playlist-toggle", toggle_playlist)
mp.observe_property("playlist-pos", "number", function() refresh_playlist() end)
mp.observe_property("playlist-count", "number", function() refresh_playlist() end)
