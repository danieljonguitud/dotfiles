-- autoformat.lua
--
-- Use your language server to automatically format your code on save.
-- Adds additional commands as well to manage the behavior

return {
  'neovim/nvim-lspconfig',
  config = function()
    -- Switch for controlling whether you want autoformatting.
    --  Use :KickstartFormatToggle to toggle autoformatting on or off
    local format_is_enabled = true
    vim.api.nvim_create_user_command('KickstartFormatToggle', function()
      format_is_enabled = not format_is_enabled
      print('Setting autoformatting to: ' .. tostring(format_is_enabled))
    end, {})

    -- Create an augroup that is used for managing our formatting autocmds.
    --      We need one augroup per client to make sure that multiple clients
    --      can attach to the same buffer without interfering with each other.
    local _augroups = {}
    local get_augroup = function(client)
      if not _augroups[client.id] then
        local group_name = 'kickstart-lsp-format-' .. client.name
        local id = vim.api.nvim_create_augroup(group_name, { clear = true })
        _augroups[client.id] = id
      end

      return _augroups[client.id]
    end

    -- Whenever an LSP attaches to a buffer, we will run this function.
    --
    -- See `:help LspAttach` for more information about this autocmd event.
    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('kickstart-lsp-attach-format', { clear = true }),
      callback = function(args)
        local bufnr = args.buf

        -- Only set up once per buffer
        if vim.b[bufnr].format_autocmd_set then
          return
        end
        vim.b[bufnr].format_autocmd_set = true

        -- Create an autocmd that will run *before* we save the buffer.
        -- Picks the appropriate formatter based on attached LSPs.
        vim.api.nvim_create_autocmd('BufWritePre', {
          buffer = bufnr,
          callback = function()
            if not format_is_enabled then
              return
            end

            local clients = vim.lsp.get_clients({ bufnr = bufnr })

            -- Check what formatters are available
            local has_biome = false
            local has_eslint = false

            for _, client in ipairs(clients) do
              if client.name == 'biome' then has_biome = true end
              if client.name == 'eslint' then has_eslint = true end
            end

            -- Pick formatter: biome > eslint > default
            if has_biome then
              vim.lsp.buf.code_action({
                apply = true,
                context = { only = { 'source.fixAll.biome' }, diagnostics = {} },
              })
              vim.lsp.buf.format({ async = false, name = 'biome' })
            elseif has_eslint then
              vim.cmd('EslintFixAll')
            else
              vim.lsp.buf.code_action({
                apply = true,
                context = { only = { 'source.fixAll' }, diagnostics = {} },
              })
              vim.lsp.buf.format({ async = false })
            end
          end,
        })
      end,
    })
  end,
}
