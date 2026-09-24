-- Keep the current function/class signature pinned at the top of the window
vim.pack.add({ "https://github.com/nvim-treesitter/nvim-treesitter-context" })

require("treesitter-context").setup({
  max_lines = 3, -- don't let the pinned header eat the screen
  multiline_threshold = 1, -- show only the first line of a multi-line signature
  trim_scope = "outer", -- when over max_lines, drop outer scopes first
})

vim.keymap.set("n", "<leader>tc", "<cmd>TSContext toggle<CR>", { desc = "[T]oggle treesitter [c]ontext" })
vim.keymap.set("n", "[x", function()
  require("treesitter-context").go_to_context(vim.v.count1)
end, { desc = "Jump to conte[x]t (function signature)" })
