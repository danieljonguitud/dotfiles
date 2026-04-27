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
		local provider = nil
		for _, pane_info in ipairs(tab.panes) do
			local info = llm.get_pane_info(pane_info.pane_id)
			if info then
				is_llm = true
				repo = repo or info.repo
				provider = provider or info.provider
			end
		end

		if not is_llm then
			return { { Text = ' ' .. idx .. ':' .. tab.active_pane.title .. ' ' } }
		end

		local label = nil
		local bg = '#D97706'
		local fg = '#1a1b26'

		if provider and provider.name == 'pi' then
			-- Keep Pi's own terminal title; only style the tab.
			label = tab.active_pane.title
			bg = '#000000'
			fg = '#ffffff'
			if not tab.is_active then
				bg = p.bg
				fg = p.bg == '#1a1b26' and '#ffffff' or '#000000'
			end
		else
			local short_label = (provider and provider.short_label) or 'llm'
			label = repo and (short_label .. ' - ' .. repo) or short_label
			if not tab.is_active then
				bg = p.bg
				fg = '#D97706'
			end
		end

		return {
			{ Background = { Color = bg } },
			{ Foreground = { Color = fg } },
			{ Text = ' ' .. idx .. ':' .. label .. ' ' },
		}
	end)
end

return M
