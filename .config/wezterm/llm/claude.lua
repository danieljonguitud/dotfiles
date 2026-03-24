local M = {}

M.name = 'claude'

-- Patterns that indicate Claude is waiting for user confirmation
local waiting_patterns = {
	'yes, allow once',
	'yes, allow always',
	'no, and tell',
	'do you trust',
	'esc to cancel',
}

-- Check if this pane belongs to Claude Code based on title
function M.is_match(title)
	if title:find('\xe2\xa0', 1, true) then return true end
	if title:find('✳', 1, true) then return true end
	return false
end

-- Detect status from title and pane content
-- utils is passed in from the abstraction layer
function M.detect(pane, title, utils)
	-- Braille dots = working
	if title:find('\xe2\xa0', 1, true) then
		return 'working'
	end

	-- ✳ = idle or waiting — check pane content
	if title:find('✳', 1, true) then
		local bottom = utils.get_pane_bottom(pane, 10)
		if bottom and utils.matches_any(bottom, waiting_patterns) then
			return 'waiting'
		end
		return 'idle'
	end

	return nil
end

return M
