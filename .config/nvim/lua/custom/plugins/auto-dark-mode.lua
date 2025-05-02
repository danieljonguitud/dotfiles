return {
  "f-person/auto-dark-mode.nvim",
  -- Optional but recommended: Make sure lualine is loaded before this runs
  dependencies = { 'nvim-lualine/lualine.nvim' },
  config = function()
    require("auto-dark-mode").setup({
      update_interval = 500,
      set_dark_mode = function()
        vim.api.nvim_set_option("background", "dark")
        vim.cmd("colorscheme tokyonight-night")
        -- Update lualine theme
        -- Use pcall for safety, in case lualine isn't loaded yet for some reason
        local success, lualine = pcall(require, 'lualine')
        if success then
          lualine.setup({ options = { theme = 'tokyonight-night' } })
        else
          vim.notify("Could not update lualine theme: lualine not found.", vim.log.levels.WARN)
        end
      end,
      set_light_mode = function()
        vim.api.nvim_set_option("background", "light")
        vim.cmd("colorscheme tokyonight-day")
        -- Update lualine theme
        local success, lualine = pcall(require, 'lualine')
        if success then
          lualine.setup({ options = { theme = 'tokyonight-day' } })
        else
          vim.notify("Could not update lualine theme: lualine not found.", vim.log.levels.WARN)
        end
      end,
    })
    -- Optionally, trigger an initial check when the plugin loads
    require("auto-dark-mode").init()
  end,
}
