local wezterm = require 'wezterm'
local act = wezterm.action

local M = {}

-- Cache for status detection results
-- Structure: { pane_id -> { status, timestamp } }
local status_cache = {}
local CACHE_TTL_MS = 3000

-- Track previous status per workspace for transition detection
local prev_status = {}

-- Workspace to switch to when WezTerm regains focus
local pending_workspace = nil

-- Patterns that indicate Claude is waiting for user confirmation
local waiting_patterns = {
	'yes, allow once',
	'yes, allow always',
	'no, and tell',
	'do you trust',
	'esc to cancel',
}

-- ANSI escape code stripping
local function strip_ansi(text)
	if not text then return '' end
	local result = text
	result = result:gsub('\27%[%d*;?%d*;?%d*[A-Za-z]', '')
	result = result:gsub('\27%].-\007', '')
	result = result:gsub('\27%].-\27\\', '')
	result = result:gsub('\27%[%?%d+[hl]', '')
	result = result:gsub('\27%[%d*[ABCDEFGJKST]', '')
	result = result:gsub('\27%[%d*;%d*[Hf]', '')
	result = result:gsub('\27%[%d*m', '')
	result = result:gsub('\27%[[0-9;]*m', '')
	result = result:gsub('\r', '')
	return result
end

-- Get last N lines from text
local function get_last_lines(text, n)
	if not text then return '' end
	local lines = {}
	for line in text:gmatch('[^\n]+') do
		table.insert(lines, line)
	end
	local start = math.max(1, #lines - n + 1)
	local result = {}
	for i = start, #lines do
		table.insert(result, lines[i])
	end
	return table.concat(result, '\n')
end

-- Check if text matches any pattern in a list
local function matches_any(text, patterns)
	if not text or not patterns then return false end
	local text_lower = text:lower()
	for _, pattern in ipairs(patterns) do
		if text_lower:find(pattern:lower(), 1, true) then
			return true
		end
	end
	return false
end

-- Check if cache entry is still valid
local function is_cache_valid(entry)
	if not entry then return false end
	local now = os.time() * 1000
	return (now - entry.timestamp) < CACHE_TTL_MS
end

-- Detect detailed status from pane content when title shows ✳
local function detect_idle_or_waiting(pane)
	local success, text = pcall(function()
		return pane:get_lines_as_text(30)
	end)
	if not success or not text then return 'idle' end

	local clean = strip_ansi(text)
	local bottom = get_last_lines(clean, 10)

	-- Check for permission prompts in the last 10 lines
	if matches_any(bottom, waiting_patterns) then
		return 'waiting'
	end

	return 'idle'
end

-- Detect Claude status for a single pane (with cache)
local function detect_pane_status(pane)
	local pane_id = pane:pane_id()

	local cached = status_cache[pane_id]
	if is_cache_valid(cached) then
		return cached.status
	end

	local title = pane:get_title()
	local status = nil

	-- Claude Code working state: braille dots (U+2800-U+28FF)
	if title:find('\xe2\xa0', 1, true) then
		status = 'working'
	elseif title:find('✳', 1, true) then
		-- Title shows idle — check bottom of pane for permission prompts
		status = detect_idle_or_waiting(pane)
	end

	if status then
		status_cache[pane_id] = {
			status = status,
			timestamp = os.time() * 1000,
		}
	end

	return status
end

function M.get_status()
	local status = {}
	local cwd = {}
	for _, mux_win in ipairs(wezterm.mux.all_windows()) do
		local ws = mux_win:get_workspace()
		for _, tab in ipairs(mux_win:tabs()) do
			for _, p in ipairs(tab:panes()) do
				local s = detect_pane_status(p)
				if s then
					-- Priority: waiting > working > idle
					local current = status[ws]
					if not current
						or (s == 'waiting')
						or (s == 'working' and current ~= 'waiting')
					then
						status[ws] = s
						cwd[ws] = tostring(p:get_current_working_dir() or '')
					end
				end
			end
		end
	end
	return status, cwd
end

local notification_messages = {
	idle = { title = '○ Task Complete', body = 'Finished in' },
	waiting = { title = '◔ Action Required', body = 'Needs your input in' },
}

function M.notify_if_unfocused(window, workspace_name, new_status, pane_cwd)
	local success, stdout = wezterm.run_child_process({
		'osascript', '-e', 'tell application "System Events" to get name of first application process whose frontmost is true'
	})
	if success then
		local frontmost = stdout:gsub('%s+$', '')
		if frontmost ~= 'wezterm-gui' then
			local repo = ''
			if pane_cwd then
				local dir = pane_cwd:gsub('^file://[^/]*', '')
				local ok, name = wezterm.run_child_process({
					'git', '-C', dir, 'rev-parse', '--show-toplevel'
				})
				if ok then
					repo = name:gsub('%s+$', ''):match('[^/]+$') or ''
				end
			end
			local notif = notification_messages[new_status] or notification_messages.idle
			local msg = notif.body .. ' ' .. workspace_name
			if repo ~= '' then
				msg = msg .. ' (' .. repo .. ')'
			end
			window:toast_notification('Claude Code — ' .. notif.title, msg)
			pending_workspace = workspace_name
		end
	end
end

function M.check_transitions(window, status, cwd)
	for ws, s in pairs(status) do
		local prev = prev_status[ws]
		-- Notify on working -> idle/waiting
		if (s == 'idle' or s == 'waiting') and prev == 'working' then
			M.notify_if_unfocused(window, ws, s, cwd[ws])
		-- Notify on idle -> waiting (permission prompt appeared after completion)
		elseif s == 'waiting' and prev == 'idle' then
			M.notify_if_unfocused(window, ws, s, cwd[ws])
		end
	end
	prev_status = status
end

function M.apply_focus_handler()
	wezterm.on('window-focus-changed', function(window, pane)
		if pending_workspace and window:is_focused() then
			local target = pending_workspace
			pending_workspace = nil
			window:perform_action(act.SwitchToWorkspace { name = target }, pane)
		end
	end)
end

return M
