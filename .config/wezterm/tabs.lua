local wezterm = require 'wezterm'
local llm = require 'llm'

local M = {}

function M.apply(get_palette)
	wezterm.on('format-tab-title', function(tab, tabs, panes, config, hover, max_width)
		local p = get_palette()
		local idx = tab.tab_index + 1

		-- Check if any pane is an LLM session
		local is_llm = false
		local repo = nil
		for _, pane_info in ipairs(tab.panes) do
			local info = llm.get_pane_info(pane_info.pane_id)
			if info then
				is_llm = true
				repo = repo or info.repo
			end
		end

		if not is_llm then
			return { { Text = ' ' .. idx .. ':' .. tab.active_pane.title .. ' ' } }
		end

		local label = repo and ('cc - ' .. repo) or 'cc'
		local bg = '#D97706'
		local fg = '#1a1b26'
		if not tab.is_active then
			bg = p.bg
			fg = '#D97706'
		end

		return {
			{ Background = { Color = bg } },
			{ Foreground = { Color = fg } },
			{ Text = ' ' .. idx .. ':' .. label .. ' ' },
		}
	end)
end

return M
