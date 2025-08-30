return {
  width = 50,
	row = nil,
	col = nil,
	pane_gap = 4,
	autokeys = "1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ",
  preset = {
    pick = nil,
		keys = {
			{ key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
			{ key = "n", desc = "New File", action = ":ene | startinsert" },
			{ key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
			{ key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
			{ key = "c", desc = "Config", action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
			{ key = "l", desc = "Lazy", action = ":Lazy", enabled = package.loaded.lazy ~= nil },
			{ key = "q", desc = "Quit", action = ":qa" },
		},

		header = [[
██████████████████████████████████████████████████
█████ ████████████████████████████████████████
████   ███  ████████████████  █ ███████████
███     █     █     ██  ████ █ ███
██  █       ██ ██    █        ██
██  ███   █   ██ ██ █   █  █ █  ██
███████ ██    █    ███ █  █████ ██
██████████████████████████████████████████████████]],
  },

	sections = {
		{ section = "header" },
		{ section = "keys", gap = 1, padding = 1 },
		{ section = "startup" },
	},
}
