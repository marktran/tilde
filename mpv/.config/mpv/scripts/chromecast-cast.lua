local mp = require("mp")
local utils = require("mp.utils")
local options = require("mp.options")

local opts = {
    -- The options below are consumed by the shell helper scripts.
    device = "",
    catt_bin = "/usr/bin/catt",
    seek_current = true,
    min_seek_seconds = 1,
    force_default = true,
    no_subs = true,

    -- Key/state handling stays in Lua.
    bind_key = "c",
    bind_key_forced = true,
    async = true,
    control_mode_auto = true,
    control_toggle_key = "C",
    control_playpause_key = "SPACE",
    control_keys_forced = true,
    pause_local = true,
    stop_local = false,
    quit_local = false,
    cast_script = "/home/mark/.config/mpv/bin/chromecast-cast",
    control_script = "/home/mark/.config/mpv/bin/chromecast-control"
}

options.read_options(opts, "chromecast-cast")

local cast_control_active = false

local function trim(s)
    return (s or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function is_url(path)
    return path and path:match("^[%a][%w+.-]*://")
end

local function current_target()
    local path = mp.get_property("path")
    if not path or path == "" then
        return nil, "No media loaded."
    end

    if is_url(path) then
        return path, nil
    end

    if path:sub(1, 1) == "/" then
        return path, nil
    end

    local wd = mp.get_property("working-directory")
    if not wd or wd == "" then
        return path, nil
    end

    return utils.join_path(wd, path), nil
end

local function apply_local_postcast_behavior()
    if opts.pause_local then
        mp.set_property_bool("pause", true)
    end
    if opts.stop_local then
        mp.commandv("stop")
    end
    if opts.quit_local then
        mp.commandv("quit")
    end
end

local function extract_error(result, fallback)
    if result and result.error_string and result.error_string ~= "" then
        return result.error_string
    end

    if result and result.stderr and trim(result.stderr) ~= "" then
        return trim(result.stderr)
    end

    if result and result.status and result.status ~= 0 then
        return "exit " .. tostring(result.status)
    end

    return fallback
end

local function set_cast_control_mode(enabled)
    cast_control_active = enabled
    if enabled then
        mp.osd_message("Cast control ON: SPACE controls TV", 2)
    else
        mp.osd_message("Cast control OFF", 2)
    end
end

local function run_script_async(args, on_done)
    mp.command_native_async({
        name = "subprocess",
        args = args,
        playback_only = false,
        capture_stdout = true,
        capture_stderr = true,
        capture_size = 16384
    }, function(success, result, error)
        local ok = success and (not result or not result.status or result.status == 0)
        if on_done then
            on_done(ok, result, error)
        end
    end)
end

local function cast_current()
    local target, err = current_target()
    if not target then
        mp.osd_message(err, 2)
        return
    end

    local title = mp.get_property("media-title") or "media"
    local pos = mp.get_property_number("time-pos", 0) or 0
    local args = {
        opts.cast_script,
        target,
        tostring(pos)
    }

    if opts.async then
        mp.osd_message("Cast request: " .. title, 2)
        if opts.control_mode_auto then
            set_cast_control_mode(true)
        end

        run_script_async(args, function(ok, result, error)
            if not ok then
                local reason = extract_error(result, error or "cast command failed")
                mp.osd_message("Chromecast failed: " .. reason, 4)
                mp.msg.error("Chromecast cast failed: " .. reason)
                if opts.control_mode_auto then
                    set_cast_control_mode(false)
                end
                return
            end

            if opts.control_mode_auto then
                set_cast_control_mode(false)
            end
        end)

        apply_local_postcast_behavior()
        return
    end

    local result = utils.subprocess({
        args = args,
        cancellable = false,
        max_size = 16384
    })

    if result.error == "init" then
        mp.osd_message("Cast helper not found.", 3)
        mp.msg.error("Chromecast cast failed: cast helper executable not found.")
        return
    end

    if result.error then
        mp.osd_message("Chromecast failed (" .. result.error .. ")", 3)
        mp.msg.error("Chromecast cast failed: " .. tostring(result.error))
        return
    end

    if result.status ~= 0 then
        local reason = extract_error(result, "cast command failed")
        mp.osd_message("Chromecast failed: " .. reason, 4)
        mp.msg.error("Chromecast cast failed: " .. reason)
        return
    end

    mp.osd_message("Casting: " .. title, 2)
    if opts.control_mode_auto then
        set_cast_control_mode(true)
    end
    apply_local_postcast_behavior()
end

local function send_cast_control(command, extra, ok_msg)
    local args = {
        opts.control_script,
        command
    }
    if extra then
        table.insert(args, tostring(extra))
    end

    run_script_async(args, function(ok, result, error)
        if not ok then
            local reason = extract_error(result, error or "cast control failed")
            mp.osd_message("Chromecast control failed: " .. reason, 3)
            mp.msg.error("Chromecast control failed: " .. reason)
            return
        end

        if ok_msg and ok_msg ~= "" then
            mp.osd_message(ok_msg, 1)
        end
    end)
end

local function toggle_cast_control_mode()
    set_cast_control_mode(not cast_control_active)
end

local function playpause_key_handler()
    if cast_control_active then
        send_cast_control("play_toggle", nil, "TV play/pause")
        mp.set_property_bool("pause", true)
        return
    end

    mp.commandv("cycle", "pause")
end

mp.register_script_message("chromecast-cast", cast_current)
mp.register_script_message("chromecast-control-toggle", toggle_cast_control_mode)
mp.register_script_message("chromecast-control-playpause", playpause_key_handler)

local key = trim(opts.bind_key)
if key ~= "" then
    if opts.bind_key_forced then
        mp.add_forced_key_binding(key, "chromecast-cast-key", cast_current)
    else
        mp.add_key_binding(key, "chromecast-cast-key", cast_current)
    end
end

local toggle_key = trim(opts.control_toggle_key)
if toggle_key ~= "" then
    if opts.control_keys_forced then
        mp.add_forced_key_binding(toggle_key, "chromecast-control-toggle-key", toggle_cast_control_mode)
    else
        mp.add_key_binding(toggle_key, "chromecast-control-toggle-key", toggle_cast_control_mode)
    end
end

local playpause_key = trim(opts.control_playpause_key)
if playpause_key ~= "" then
    if opts.control_keys_forced then
        mp.add_forced_key_binding(playpause_key, "chromecast-control-playpause-key", playpause_key_handler)
    else
        mp.add_key_binding(playpause_key, "chromecast-control-playpause-key", playpause_key_handler)
    end
end
