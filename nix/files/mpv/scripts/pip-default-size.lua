local mp = require("mp")
local options = require("mp.options")

local opts = {
    enabled = true,
    mode = "normal",
    delay = 0.2
}

options.read_options(opts, "pip-default-size")

local resize_script = "/home/mark/.config/hypr/scripts/hypr-mpv-pip-size"
local resize_timer = nil

local function has_video()
    local vf = mp.get_property("video-format")
    return vf ~= nil and vf ~= ""
end

local function run_default_resize()
    if not opts.enabled then
        return
    end

    if mp.get_property_bool("fullscreen", false) then
        return
    end

    if not has_video() then
        return
    end

    mp.commandv("run", resize_script, opts.mode)
end

local function schedule_default_resize()
    if not opts.enabled then
        return
    end

    if resize_timer then
        resize_timer:kill()
        resize_timer = nil
    end

    local delay = tonumber(opts.delay) or 0
    if delay < 0 then
        delay = 0
    end

    resize_timer = mp.add_timeout(delay, run_default_resize)
end

mp.register_event("file-loaded", schedule_default_resize)
