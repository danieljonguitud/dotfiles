vim.keymap.set('n', '<leader>pl', ':Neotree reveal toggle<CR>', { noremap = true, silent = true })

local harpoon = require("harpoon")

-- REQUIRED
harpoon:setup({
	settings = {
		save_on_toggle = true,
		sync_on_ui_close = true,
	}
})
-- REQUIRED

vim.keymap.set("n", "<leader>m", function() harpoon:list():append() end)
vim.keymap.set("n", "<leader>h", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end)
vim.keymap.set("n", "<C-n>", function() harpoon:list():select(1) end)
vim.keymap.set("n", "<C-e>", function() harpoon:list():select(2) end)
vim.keymap.set("n", "<C-i>", function() harpoon:list():select(3) end)
vim.keymap.set("n", "<C-o>", function() harpoon:list():select(4) end)

-- Undootree
vim.keymap.set("n", "<leader>u", vim.cmd.UndotreeToggle)

-- Navigation
vim.keymap.set("v", "<S-Up>", ":m '<-2<CR>gv=gv") -- This and the next allow to highlight elements and move them with shift up/down
vim.keymap.set("v", "<S-Down>", ":m '>+1<CR>gv=gv")
vim.keymap.set("n", "J", "mzJ`z") -- This grabs whatever is down the cursor and append it to the end without moving the cursor
vim.keymap.set("n", "<S-Up>", "<C-u>zz") -- This and the next allows navigation to the middle of the screen with shift up/down
vim.keymap.set("n", "<S-Down>", "<C-d>zz")
vim.keymap.set("n", "n", "nzzzv") -- This and the next, when searching the word will be always in the middle
vim.keymap.set("n", "N", "Nzzzv")
vim.keymap.set("n", "<leader>sr", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]]) -- Search and replace the word on the cursor
vim.keymap.set("n", "<A-Left>", "B")
vim.keymap.set("n", "<A-Right>", "W")
