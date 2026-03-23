local wezterm = require 'wezterm'
local act = wezterm.action
local claude = require 'claude_status'

local M = {}

local working_spinner = { '◐', '◓', '◑', '◒' }
local spinner_frame = 0

local icons = {
	waiting = '◔',
	idle = '○',
}

local palettes = {
	dark = {
		bg = '#1a1b26',
		fg_dim = '#565f89',
		fg_active = '#1a1b26',
		active = '#7aa2f7',
		working = '#7aa2f7',
		waiting = '#e0af68',
		idle = '#9ece6a',
	},
	light = {
		bg = '#d5d6db',
		fg_dim = '#8990b3',
		fg_active = '#d5d6db',
		active = '#2e7de9',
		working = '#2e7de9',
		waiting = '#8c6c3e',
		idle = '#587539',
	},
}

function M.get_palette()
	local appearance = 'Dark'
	if wezterm.gui then
		appearance = wezterm.gui.get_appearance()
	end
	if appearance:find('Dark') then
		return palettes.dark
	end
	return palettes.light
end

-- Ordered workspace list that preserves creation order
local workspace_order = {}
local workspace_set = {}

function M.sync_order()
	local current = {}
	local names = wezterm.mux.get_workspace_names()
	for _, name in ipairs(names) do
		current[name] = true
		if not workspace_set[name] then
			-- On first sync (config reload), "default" always goes first
			if name == 'default' and #workspace_order > 0 and workspace_order[1] ~= 'default' then
				table.insert(workspace_order, 1, name)
			else
				table.insert(workspace_order, name)
			end
			workspace_set[name] = true
		end
	end
	-- Remove workspaces that no longer exist
	local filtered = {}
	for _, name in ipairs(workspace_order) do
		if current[name] then
			table.insert(filtered, name)
		else
			workspace_set[name] = nil
		end
	end
	workspace_order = filtered
end

function M.get_order()
	return workspace_order
end

function M.rename(old_name, new_name)
	wezterm.mux.rename_workspace(old_name, new_name)
	for i, name in ipairs(workspace_order) do
		if name == old_name then
			workspace_order[i] = new_name
			break
		end
	end
	workspace_set[old_name] = nil
	workspace_set[new_name] = true
end

function M.apply_keys(config)
	-- Workspace keybindings
	local workspace_keys = {
		{
			key = 'n',
			mods = 'CMD|OPT',
			action = act.PromptInputLine {
				description = wezterm.format {
					{ Attribute = { Intensity = 'Bold' } },
					{ Foreground = { AnsiColor = 'Fuchsia' } },
					{ Text = 'Enter name for new workspace' },
				},
				action = wezterm.action_callback(function(window, pane, line)
					if line then
						window:perform_action(
							act.SwitchToWorkspace { name = line },
							pane
						)
					end
				end),
			},
		},
		{
			key = 'w',
			mods = 'LEADER',
			action = act.ShowLauncherArgs { flags = 'FUZZY|WORKSPACES' },
		},
		{
			key = 'r',
			mods = 'CMD|OPT',
			action = act.PromptInputLine {
				description = wezterm.format {
					{ Attribute = { Intensity = 'Bold' } },
					{ Foreground = { AnsiColor = 'Fuchsia' } },
					{ Text = 'Rename workspace to:' },
				},
				action = wezterm.action_callback(function(window, pane, line)
					if line then
						M.rename(window:active_workspace(), line)
					end
				end),
			},
		},
	}

	for _, key in ipairs(workspace_keys) do
		table.insert(config.keys, key)
	end

	-- CMD+OPT+1-9 to switch workspace by index
	for i = 1, 9 do
		table.insert(config.keys, {
			key = tostring(i),
			mods = 'CMD|OPT',
			action = wezterm.action_callback(function(window, pane)
				M.sync_order()
				local order = M.get_order()
				if order[i] then
					window:perform_action(act.SwitchToWorkspace { name = order[i] }, pane)
				end
			end),
		})
	end
end

function M.apply_status_bar()
	wezterm.on('update-status', function(window, pane)
		local active_workspace = window:active_workspace()
		M.sync_order()

		local claude_status, claude_cwd = claude.get_status()
		claude.check_transitions(window, claude_status, claude_cwd)

		local p = M.get_palette()

		-- Advance spinner frame if any workspace is working
		local any_working = false
		for _, s in pairs(claude_status) do
			if s == 'working' then any_working = true break end
		end
		if any_working then
			spinner_frame = (spinner_frame + 1) % #working_spinner
		end

		local cells = {}
		for i, name in ipairs(workspace_order) do
			local is_active = name == active_workspace
			local cs = claude_status[name]
			local icon = nil
			if cs == 'working' then
				icon = working_spinner[spinner_frame + 1]
			elseif cs then
				icon = icons[cs]
			end
			local label = i .. ':' .. name
			if icon then
				label = i .. ':' .. icon .. ' ' .. name
			end

			-- Separator
			if #cells > 0 then
				table.insert(cells, { Foreground = { Color = p.fg_dim } })
				table.insert(cells, { Background = { Color = p.bg } })
				table.insert(cells, { Text = ' | ' })
			end

			-- Pick color based on active state and claude status
			local bg = p.bg
			local fg = p.fg_dim

			if is_active and cs then
				bg = p[cs]
				fg = p.fg_active
			elseif is_active then
				bg = p.active
				fg = p.fg_active
			elseif cs then
				fg = p[cs]
			end

			table.insert(cells, { Foreground = { Color = fg } })
			table.insert(cells, { Background = { Color = bg } })
			table.insert(cells, { Text = ' ' .. label .. ' ' })
		end

		window:set_right_status(wezterm.format(cells))
	end)

	claude.apply_focus_handler()
end

return M
