-- Extra autostart processes.
-- (hyprsunset now runs as a systemd user service; no exec-once needed.)
o.launch_on_start("1password --silent")
