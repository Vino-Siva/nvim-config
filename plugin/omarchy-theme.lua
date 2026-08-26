local theme_file = vim.fn.expand("~/.local/state/omarchy/current/theme/neovim.lua")
local watcher
local timer

local function notify(message, level)
	vim.notify(message, level, { title = "Omarchy theme" })
end

local function load_theme()
	local chunk, load_error = loadfile(theme_file)

	if not chunk then
		notify(("Cannot read theme file: %s"):format(load_error), vim.log.levels.WARN)
		return
	end

	local ok, spec = pcall(chunk)

	if not ok or type(spec) ~= "table" then
		notify("Theme file returned an invalid specification.", vim.log.levels.WARN)
		return
	end

	local plugin = spec[1]
	local lazyvim = spec[2]
	local repo = type(plugin) == "table" and plugin[1] or nil
	local colorscheme = lazyvim and type(lazyvim.opts) == "table" and lazyvim.opts.colorscheme or nil

	if type(repo) ~= "string" or type(colorscheme) ~= "string" then
		notify("Could not determine the theme repository or colorscheme.", vim.log.levels.WARN)
		return
	end

	local name = repo:match("/([^/]+)$")
	if not name then
		notify(("Invalid theme repository: %s"):format(repo), vim.log.levels.WARN)
		return
	end

	vim.pack.add({
		{
			src = "https://github.com/" .. repo,
			name = name,
		},
	})

	vim.schedule(function()
		local applied, colorscheme_error = pcall(vim.cmd.colorscheme, colorscheme)

		if not applied then
			notify(("Could not apply %q: %s"):format(colorscheme, colorscheme_error), vim.log.levels.ERROR)
			return
		end

		notify(("Applied %s."):format(colorscheme), vim.log.levels.INFO)
	end)
end

load_theme()

watcher = vim.uv.new_fs_event()
watcher:start(theme_file, {}, function(error)
	if error then
		vim.schedule(function()
			notify(("Theme watcher error: %s"):format(error), vim.log.levels.ERROR)
		end)
		return
	end

	if timer then
		timer:stop()
		timer:close()
	end

	timer = vim.uv.new_timer()
	timer:start(
		150,
		0,
		vim.schedule_wrap(function()
			timer:stop()
			timer:close()
			timer = nil
			load_theme()
		end)
	)
end)

vim.api.nvim_create_autocmd("VimLeavePre", {
	callback = function()
		if watcher and not watcher:is_closing() then
			watcher:stop()
			watcher:close()
		end

		if timer and not timer:is_closing() then
			timer:stop()
			timer:close()
		end
	end,
})
