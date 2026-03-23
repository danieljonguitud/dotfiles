local wezterm = require 'wezterm'
local act = wezterm.action

local M = {}

-- Track previous status per workspace for transition detection
local prev_status = {}

-- Workspace to switch to when WezTerm regains focus
local pending_workspace = nil

function M.get_status()
	local status = {}
	local cwd = {}
	for _, mux_win in ipairs(wezterm.mux.all_windows()) do
		local ws = mux_win:get_workspace()
		for _, tab in ipairs(mux_win:tabs()) do
			for _, p in ipairs(tab:panes()) do
				local title = p:get_title()
				-- Claude Code working state: braille dots (U+2800-U+28FF)
				-- All encode as e2 a0 xx in UTF-8, match the 2-byte prefix
				if title:find('\xe2\xa0', 1, true) then
					status[ws] = 'working'
					cwd[ws] = tostring(p:get_current_working_dir() or '')
				elseif title:find('✳', 1, true) and status[ws] ~= 'working' then
					status[ws] = 'idle'
					cwd[ws] = tostring(p:get_current_working_dir() or '')
				end
			end
		end
	end
	return status, cwd
end

function M.notify_if_unfocused(window, workspace_name, pane_cwd)
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
			local msg = 'Waiting for input in ' .. workspace_name
			if repo ~= '' then
				msg = msg .. ' (' .. repo .. ')'
			end
			window:toast_notification('Claude Code', msg)
			pending_workspace = workspace_name
		end
	end
end

function M.check_transitions(window, status, cwd)
	for ws, s in pairs(status) do
		if s == 'idle' and prev_status[ws] == 'working' then
			M.notify_if_unfocused(window, ws, cwd[ws])
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
