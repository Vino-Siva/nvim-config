local function gh(repo)
  return "https://github.com/" .. repo
end

do
  -- plenary.nvim and nvim-lspconfig are dependencies of this plugin, but they are already added earlier
  -- (alphabetically) by neo-tree.lua and lsp-config.lua respectively; re-adding them here would be a no-op
  -- (see :help vim.pack.add()) and just duplicate the spec.
  vim.pack.add({ gh("pmizio/typescript-tools.nvim") })

  require("typescript-tools").setup({})
end
