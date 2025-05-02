-- Unless you are still migrating, remove the deprecated commands from v1.x

return {
  "nvim-neo-tree/neo-tree.nvim",
  version = "*",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
    "MunifTanjim/nui.nvim",
  },
  config = function ()
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
        hijak_netrw_behaviour = "open_current",
      }
    })
  end,
}
