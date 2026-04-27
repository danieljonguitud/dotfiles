local M = {}

M.name = 'pi'
M.label = 'Pi'
M.short_label = 'pi'

local title_prefixes = {
	'π',
	'pi',
}

local function has_title_prefix(title, prefix)
	local lower = title:lower()
	local lower_prefix = prefix:lower()
	return title == prefix
		or lower == lower_prefix
		or title:sub(1, #prefix + 3) == prefix .. ' - '
		or lower:sub(1, #lower_prefix + 3) == lower_prefix .. ' - '
end

local working_patterns = {
	'Working...',
	'to interrupt',
	'Compacting context',
	'Auto-compacting',
}

local waiting_patterns = {
	'Allow dangerous command?',
	'Delete session?',
	'Select provider to configure:',
	'Select provider to logout:',
	'Resource Configuration',
	'Resume Session',
	'Rename Session',
	'Enter to select',
	'to submit',
	'to cancel',
}

local function title_matches(title)
	if not title or title == '' then return false end
	for _, prefix in ipairs(title_prefixes) do
		if has_title_prefix(title, prefix) then
			return true
		end
	end
	return false
end

-- Pi sets the terminal title to "π - <cwd>" by default (or "pi - <cwd>"
-- when configured with a named agent), so use the title to identify panes.
function M.is_match(title)
	return title_matches(title)
end

function M.detect(pane, title, utils)
	if not title_matches(title) then return nil end

	local bottom = utils.get_pane_bottom(pane, 12)
	if bottom and utils.matches_any(bottom, waiting_patterns) then
		return 'waiting'
	end
	if bottom and utils.matches_any(bottom, working_patterns) then
		return 'working'
	end

	return 'idle'
end

return M
