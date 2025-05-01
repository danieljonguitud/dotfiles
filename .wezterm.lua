-- Pull in the wezterm API
local wezterm = require 'wezterm'
local act = wezterm.action

-- This table will hold the configuration.
local config = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
  config = wezterm.config_builder()
end

function get_appearance()
  if wezterm.gui then
    return wezterm.gui.get_appearance()
  end
  return 'Dark'
end

function scheme_for_appearance(appearance)
  if appearance:find 'Dark' then
    return 'Dark+'
  else
    return 'One Light (base16)'
  end
end

-- This is where you actually apply your config choices

config.font = wezterm.font 'JetBrainsMono Nerd Font'
config.font_size = 14.0
config.font_rules = {
  {
    intensity = "Bold",
    italic = false,
    font = wezterm.font("JetBrainsMono Nerd Font",
      {
	weight = "Bold",
	stretch = "Normal",
	style = "Normal"
      }
    ),
  },
  {
    intensity = "Bold",
    italic = true,
    font = wezterm.font("JetBrainsMono Nerd Font",
      { weight = "Bold",
	stretch = "Normal",
	style = "Italic"
      }
    ),
  },
}
config.color_scheme = scheme_for_appearance(get_appearance())
config.window_padding = {
  left = 10,
  right = 0,
  top = 10,
  bottom = 0,
}

-- Tabs
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true
config.show_new_tab_button_in_tab_bar = false
config.tab_bar_at_bottom = true

-- Hotkeys config
config.leader = { key = 'a', mods = 'CTRL' }
config.keys = {
  {
    key = 'm',
    mods = 'LEADER',
    action = act.TogglePaneZoomState,
  },
  {
    key = '|',
    mods = 'LEADER',
    action = act.SplitHorizontal { domain = 'CurrentPaneDomain'},
  },
  {
    key = '-',
    mods = 'LEADER',
    action = act.SplitVertical { domain = 'CurrentPaneDomain'},
  },
  {
    key = '-',
    mods = 'LEADER',
    action = act.SplitVertical { domain = 'CurrentPaneDomain'},
  },
  {
    key = 'LeftArrow',
    mods = 'LEADER',
    action = act.ActivatePaneDirection 'Left'
  },
  {
    key = 'RightArrow',
    mods = 'LEADER',
    action = act.ActivatePaneDirection 'Right'
  },
  {
    key = 'UpArrow',
    mods = 'LEADER',
    action = act.ActivatePaneDirection 'Up'
  },
  {
    key = 'DownArrow',
    mods = 'LEADER',
    action = act.ActivatePaneDirection 'Down'
  },
  {
    key = 'r',
    mods = 'LEADER',
    action = act.ActivateKeyTable {
      name = 'resize_pane',
      one_shot = false,
    },
  },
}

config.key_tables = {
  resize_pane = {
    {
      key = 'DownArrow',
      action = act.AdjustPaneSize { 'Down', 5 }
    },
    {
      key = 'UpArrow',
      action = act.AdjustPaneSize { 'Up', 5 }
    },
    {
      key = 'LeftArrow',
      action = act.AdjustPaneSize { 'Left', 5 }
    },
    {
      key = 'RightArrow',
      action = act.AdjustPaneSize { 'Right', 5 }
    },
    { key = 'Escape', action = 'PopKeyTable' },
  },
}

config.window_decorations = "RESIZE"


-- and finally, return the configuration to wezterm
return config
