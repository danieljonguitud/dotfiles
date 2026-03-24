local wezterm = require 'wezterm'
local act = wezterm.action

local M = {}

-- Track previous status per workspace for transition detection
local prev_status = {}

-- Workspace to switch to when WezTerm regains focus
local pending_workspace = nil

local messages = {
	idle = { title = '○ Task Complete', body = 'Finished in' },
	waiting = { title = '◔ Action Required', body = 'Needs your input in' },
}

-- Get git repo name from a cwd string
local function get_repo_from_cwd(cwd)
	if not cwd or cwd == '' then return nil end
	local dir = cwd:gsub('^file://[^/]*', '')
	local ok, name = wezterm.run_child_process({
		'git', '-C', dir, 'rev-parse', '--show-toplevel'
	})
	if ok then
		return name:gsub('%s+$', ''):match('[^/]+$')
	end
	return nil
end

local function notify_if_unfocused(window, workspace_name, new_status, pane_cwd)
	local success, stdout = wezterm.run_child_process({
		'osascript', '-e', 'tell application "System Events" to get name of first application process whose frontmost is true'
	})
	if success then
		local frontmost = stdout:gsub('%s+$', '')
		if frontmost ~= 'wezterm-gui' then
			local repo = get_repo_from_cwd(pane_cwd) or ''
			local notif = messages[new_status] or messages.idle
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
			notify_if_unfocused(window, ws, s, cwd[ws])
		-- Notify on idle -> waiting (permission prompt appeared after completion)
		elseif s == 'waiting' and prev == 'idle' then
			notify_if_unfocused(window, ws, s, cwd[ws])
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
