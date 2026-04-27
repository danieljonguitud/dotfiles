local wezterm = require 'wezterm'

local M = {}

-- Resolve path relative to this file
local config_dir = wezterm.config_dir
local providers = {
	dofile(config_dir .. '/llm/claude.lua'),
	dofile(config_dir .. '/llm/pi.lua'),
}

-- Cache for status detection results
local status_cache = {}
local CACHE_TTL_MS = 3000

-- Shared utilities passed to providers
local utils = {}

function utils.strip_ansi(text)
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

function utils.get_last_lines(text, n)
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

function utils.matches_any(text, patterns)
	if not text or not patterns then return false end
	local text_lower = text:lower()
	for _, pattern in ipairs(patterns) do
		if text_lower:find(pattern:lower(), 1, true) then
			return true
		end
	end
	return false
end

-- Read and clean the bottom N lines of a pane
function utils.get_pane_bottom(pane, n)
	local success, text = pcall(function()
		return pane:get_lines_as_text(30)
	end)
	if not success or not text then return nil end
	local clean = utils.strip_ansi(text)
	return utils.get_last_lines(clean, n)
end

-- Check if cache entry is still valid
local function is_cache_valid(entry)
	if not entry then return false end
	local now = os.time() * 1000
	return (now - entry.timestamp) < CACHE_TTL_MS
end

-- Detect status for a single pane across all providers
local function detect_pane_status(pane)
	local pane_id = pane:pane_id()

	local cached = status_cache[pane_id]
	if is_cache_valid(cached) then
		return cached.status, cached.provider
	end

	local title = pane:get_title() or ''
	if title == '' then return nil end

	for _, provider in ipairs(providers) do
		if provider.is_match(title) then
			local status = provider.detect(pane, title, utils)
			if status then
				status_cache[pane_id] = {
					status = status,
					provider = provider,
					timestamp = os.time() * 1000,
				}
				return status, provider
			end
		end
	end

	return nil
end

-- Stable per-pane info (only updated when status/repo actually changes)
local pane_info = {}

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

-- Pure lookup — safe to call from format-tab-title
function M.get_pane_info(pane_id)
	return pane_info[pane_id]
end

function M.get_status()
	local status = {}
	local cwd = {}
	local provider_by_ws = {}
	local seen = {}
	for _, mux_win in ipairs(wezterm.mux.all_windows()) do
		local ws = mux_win:get_workspace()
		for _, tab in ipairs(mux_win:tabs()) do
			for _, p in ipairs(tab:panes()) do
				local pid = p:pane_id()
				local s, provider = detect_pane_status(p)
				seen[pid] = true
				if s then
					local pane_cwd = tostring(p:get_current_working_dir() or '')
					-- Only update pane_info if status or repo changed
					local existing = pane_info[pid]
					if not existing or existing.status ~= s or existing.provider ~= provider then
						local repo = get_repo_from_cwd(pane_cwd)
						pane_info[pid] = { status = s, repo = repo, provider = provider }
					elseif not existing.repo then
						existing.repo = get_repo_from_cwd(pane_cwd)
					end
					-- Priority: waiting > working > idle
					local current = status[ws]
					if not current
						or (s == 'waiting')
						or (s == 'working' and current ~= 'waiting')
					then
						status[ws] = s
						cwd[ws] = pane_cwd
						provider_by_ws[ws] = provider
					end
				else
					-- LLM no longer running in this pane
					pane_info[pid] = nil
				end
			end
		end
	end
	-- Remove closed panes
	for pid in pairs(pane_info) do
		if not seen[pid] then
			pane_info[pid] = nil
		end
	end
	return status, cwd, provider_by_ws
end

return M
