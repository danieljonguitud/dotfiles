-- Unless you are still migrating, remove the deprecated commands from v1.x

return {
  "nvim-neo-tree/neo-tree.nvim",
  version = "*",
  lazy = false,   -- Load immediately to prevent netrw from showing
  priority = 100, -- Load after colorscheme but before other plugins
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
    "MunifTanjim/nui.nvim",
  },
  config = function()
    require('neo-tree').setup({
      window = {
        position = "current"
      },
      close_if_last_window = true,
      filesystem = {
        filtered_items = {
          hide_dotfiles = true,
          hide_gitignored = true,
        },
        follow_current_file = {
          enabled = true,
        },
        hijack_netrw_behavior = "open_current", -- Fixed typo: was "hijak"
      }
    })

    -- Auto-open neo-tree when starting with a directory
    vim.api.nvim_create_autocmd("VimEnter", {
      callback = function()
        local args = vim.fn.argv()
        if #args == 1 and vim.fn.isdirectory(args[1]) == 1 then
          -- Show a brief loading message
          vim.cmd("echo 'Loading file explorer...'")
          -- Small delay to let everything initialize
          vim.defer_fn(function()
            vim.cmd("Neotree filesystem reveal")
            vim.cmd("echo ''") -- Clear the loading message
          end, 50)
        end
      end,
    })
  end,
}
